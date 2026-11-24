// Firm registration and membership workflow. All delayed operations retain a
// character ID and session generation; a reused player slot is never trusted.
#include <YSI_Coding\y_hooks>

// Revalidate a captured character before replying to an asynchronous request.
stock bool:Firm_SameSession(playerid,character_id,session) {
    return IsPlayerConnected(playerid) && IsPlayerLogged(playerid) && Character[playerid][E_CHARACTER_ID]==character_id && FirmSession[playerid]==session;
}

// The professional business registrations are separate from police-issued
// guard/firearms permits. These keys match the registration SQL routine.
stock Firm_GetLicenseKey(field,key[],size) {
    switch(field) {
        case FIRM_FIELD_MECHANIC:format(key,size,"mechanic");
        case FIRM_FIELD_SECURITY:format(key,size,"security_guard");
        case FIRM_FIELD_LAWYER:format(key,size,"lawyer");
        case FIRM_FIELD_TRANSIT:format(key,size,"transit");
        case FIRM_FIELD_LOGISTICS:format(key,size,"logistics");
        case FIRM_FIELD_MEDIA:format(key,size,"media");
        default:{key[0]=EOS;return 0;}
    }
    return 1;
}

// Refund a rejected reservation to its original character, even after logout.
// Successful reservations were already debited before the queued SQL request.
static Firm_RefundRegistration(character_id,fee) {
    foreach(new player:Player) if(IsPlayerLogged(player) && Character[player][E_CHARACTER_ID]==character_id) {
        GivePlayerCash(player,fee,"Rejected firm registration refund");return 1;
    }
    new query[160];mysql_format(mysql,query,sizeof query,"UPDATE characters SET player_cash=player_cash+%d WHERE player_id=%d",fee,character_id);mysql_tquery(mysql,query);
    return 1;
}

// /firmlicense [field] completes the otherwise missing first step. Registration
// is free and idempotent; the separate firm creation fee is quoted by /firmcreate.
CMD:firmlicense(playerid,params[]) {
    if(!Firm_PlayerCanAccess(playerid))return Firm_SendAccessDenied(playerid);
    if(!IsAtGovFrontDesk(playerid))return SendClientMessage(playerid,COLOR_ERROR,"Visit the configured Administration Building front desk to register a professional business licence.");
    new field_name[16],key[32];
    if(sscanf(params,"s[16]",field_name))return SendClientMessage(playerid,COLOR_INFO,"/firmlicense [mechanic/security/lawyer/transit/logistics/media] - free business registration");
    new field=Firm_ParseField(field_name);
    if(!Firm_IsValidField(field))return SendClientMessage(playerid,COLOR_ERROR,"Unknown firm field. Use /firmhelp.");
    if(!Firm_GetLicenseKey(field,key,sizeof key))return SendClientMessage(playerid,COLOR_INFO,"Used-car and real-estate firms need no professional licence. Use /firmcreate.");
    new character_id=Character[playerid][E_CHARACTER_ID],session=FirmSession[playerid],query[384];
    mysql_format(mysql,query,sizeof query,"INSERT IGNORE INTO character_licenses(character_id,license_type,issued_by,issued_at) VALUES(%d,'%e',0,NOW())",character_id,key);
    inline Firm_LicenseIssued() {
        if(!Firm_SameSession(playerid,character_id,session))return 1;
        new licence_name[32];Firm_GetRequiredLicenseName(field,licence_name,sizeof licence_name);
        SendClientMessage(playerid,COLOR_INFO,sprintf("%s business registration is ready. Use /firmcreate [field] [abbrev] [name].",licence_name));
        if(field==FIRM_FIELD_SECURITY)SendClientMessage(playerid,COLOR_INFO,"This business registration is not a police-issued guard card or firearms permit.");
        return 1;
    }
    MySQL_TQueryInline(mysql,using inline Firm_LicenseIssued,query,"");return 1;
}

// Reserve the exact quoted fee and memory slot before queuing an atomic SQL
// registration. Owner membership is committed with the firm, not in a later query.
Firm_Create(playerid,const name[],const abbrev[],field) {
    if(!Firm_PlayerCanAccess(playerid) || !Firm_IsValidField(field) || !Firm_IsValidName(name) || !Firm_IsValidAbbrev(abbrev))return 0;
    if(FirmRegistrationPending[playerid])return SendClientMessage(playerid,COLOR_ERROR,"Your firm registration is already being processed.");
    if(IsPlayerInFirm(playerid) || !IsAtGovFrontDesk(playerid))return SendClientMessage(playerid,COLOR_ERROR,"Register at the Administration Building while not already in a firm.");
    new index=Firm_GetFreeID(),fee=Firm_GetCreateFee(field);
    if(index==INVALID_FIRM_ID)return SendClientMessage(playerid,COLOR_ERROR,"The firm limit has been reached.");
    if(GetPlayerCash(playerid)<fee)return SendClientMessage(playerid,COLOR_ERROR,sprintf("You need $%s in cash to register this firm.",IntegerWithDelimiter(fee)));
    new character_id=Character[playerid][E_CHARACTER_ID],session=FirmSession[playerid];
    new member_slots=Runtime_Int(RT_FIRMS_MEMBER_SLOTS),vehicle_slots=Runtime_Int(RT_FIRMS_VEHICLE_SLOTS);
    FirmRegistrationPending[playerid]=true;Firm_ClearEntity(index);Firm[index][E_FIRM_ID]=-2;
    new request=++FirmRequestSerial[index];FirmReservedFee[index]=fee;FirmRequestStarted[index]=gettime();FirmRequestPlayer[index]=playerid;FirmRequestSession[index]=session;
    Firm[index][E_FIRM_OWNER_CHAR_ID]=character_id;Firm[index][E_FIRM_FIELD]=field;Firm[index][E_FIRM_MEMBER_SLOTS]=member_slots;Firm[index][E_FIRM_VEHICLE_SLOTS]=vehicle_slots;
    format(Firm[index][E_FIRM_NAME],MAX_FIRM_NAME,"%s",name);format(Firm[index][E_FIRM_ABBREV],MAX_FIRM_ABBREV,"%s",abbrev);
    // Persist the debit only inside the SQL registration transaction.
    SetPlayerCash(playerid,GetPlayerCash(playerid)-fee);
    AddLogEntry(playerid,LOG_TYPE_MONEY_FLOW,sprintf("Reserved firm registration fee: $%d",fee));
    new query[512];mysql_format(mysql,query,sizeof query,"CALL orp_firm_register(%d,'%e','%e',%d,%d,%d,%d)",character_id,name,abbrev,field,member_slots,vehicle_slots,fee);
    inline Firm_Registered() {
        new id;new result[96];if(cache_num_rows()){cache_get_value_name_int(0,"firm_id",id);cache_get_value_name(0,"result",result,sizeof result);}
        return Firm_FinishRegistration(index,request,id,result);
    }
    MySQL_TQueryInline(mysql,using inline Firm_Registered,query,"");return 1;
}

// A timeout check reads behind the original query on the same SQL worker queue.
// It resolves a missing callback without creating a second firm or refunding a
// committed registration. Request generations ignore callbacks from reused slots.
Firm_FinishRegistration(index,request,id,const result[]) {
    if(Firm[index][E_FIRM_ID]!=-2 || FirmRequestSerial[index]!=request)return 1;
    new character_id=Firm[index][E_FIRM_OWNER_CHAR_ID],fee=FirmReservedFee[index],playerid=FirmRequestPlayer[index],session=FirmRequestSession[index];
    if(Firm_SameSession(playerid,character_id,session))FirmRegistrationPending[playerid]=false;
    if(id<1) {
        Firm_ClearEntity(index);Firm_RefundRegistration(character_id,fee);
        if(Firm_SameSession(playerid,character_id,session)) {
            if(!strcmp(result,"license"))SendClientMessage(playerid,COLOR_ERROR,"First use /firmlicense [field] at this desk. Your registration fee was refunded.");
            else SendClientMessage(playerid,COLOR_ERROR,"Registration was rejected. Check name, abbreviation, membership and capacity. Your fee was refunded.");
        }
        return 1;
    }
    Firm[index][E_FIRM_ID]=id;Firm[index][E_FIRM_STATUS]=FIRM_STATUS_ACTIVE;Firm[index][E_FIRM_BANK]=0;Firm[index][E_FIRM_HEXCOLOR]=0x5FB9D1FF;Firm[index][E_FIRM_CREATED_AT]=gettime();Firm[index][E_FIRM_UPDATED_AT]=gettime();
    foreach(new owner:Player)if(IsPlayerLogged(owner) && Character[owner][E_CHARACTER_ID]==character_id) {
        Firm_ClearPlayer(owner);PlayerFirm[owner][E_PLAYER_FIRM_ID]=id;PlayerFirm[owner][E_PLAYER_FIRM_RANK]=1;PlayerFirm[owner][E_PLAYER_FIRM_PERMS]=FIRM_PERM_ALL;
        SendClientMessage(owner,COLOR_INFO,sprintf("Registered %s [%s] for $%s. Use /firmhelp, /firmbank and /firminvite.",Firm[index][E_FIRM_NAME],Firm[index][E_FIRM_ABBREV],IntegerWithDelimiter(fee)));
        AddLogEntry(owner,LOG_TYPE_FIRM,sprintf("Registered firm SQL %d for $%d",id,fee));break;
    }
    Firm_Log(id,character_id,1,"Firm and owner membership registered together at the Administration Building");return 1;
}

forward Firm_CheckPending();
public Firm_CheckPending() {
    for(new index;index<MAX_FIRMS;index++)if(Firm[index][E_FIRM_ID]==-2 && gettime()-FirmRequestStarted[index]>=30) {
        FirmRequestStarted[index]=gettime();new request=FirmRequestSerial[index],query[512];
        mysql_format(mysql,query,sizeof query,"SELECT COALESCE((SELECT firm_id FROM firms WHERE firm_owner_char_id=%d AND firm_name='%e' AND firm_abbrev='%e' AND firm_status<>3 LIMIT 1),0) AS firm_id",Firm[index][E_FIRM_OWNER_CHAR_ID],Firm[index][E_FIRM_NAME],Firm[index][E_FIRM_ABBREV]);
        inline Firm_Recovered() {new id;if(!cache_num_rows())return 1;cache_get_value_name_int(0,"firm_id",id);return Firm_FinishRegistration(index,request,id,"recovery");}
        MySQL_TQueryInline(mysql,using inline Firm_Recovered,query,"");
    }
    for(new index;index<MAX_FIRMS;index++)if(FirmClosing[index] && gettime()-FirmRequestStarted[index]>=30) {
        FirmRequestStarted[index]=gettime();new id=Firm[index][E_FIRM_ID],request=FirmCloseSerial[index],query[128];
        format(query,sizeof query,"SELECT firm_status FROM firms WHERE firm_id=%d",id);
        inline Firm_CloseRecovered() {
            if(Firm[index][E_FIRM_ID]!=id || FirmCloseSerial[index]!=request || !FirmClosing[index])return 1;
            if(!cache_num_rows())return 1;
            new status;cache_get_value_name_int(0,"firm_status",status);
            if(status==FIRM_STATUS_CLOSED){Firm_SendMessage(id,"[Firm] Closure confirmed after database recovery.");Firm_Close(index);}
            else FirmClosing[index]=false;
            return 1;
        }
        MySQL_TQueryInline(mysql,using inline Firm_CloseRecovered,query,"");
    }
    return 1;
}
hook OnGameModeInit(){SetTimer("Firm_CheckPending",5000,true);return 1;}

// Recheck capacity, status and inviter authority in the same transaction as join.
// No success message/cache update is sent until the database accepts the member.
Firm_AcceptInvite(playerid,firm_sql_id,inviter_character) {
    new character_id=Character[playerid][E_CHARACTER_ID],session=FirmSession[playerid],query[160];
    if(FirmRegistrationPending[playerid])return SendClientMessage(playerid,COLOR_ERROR,"Wait for your pending firm registration first.");
    mysql_format(mysql,query,sizeof query,"CALL orp_firm_join(%d,%d,%d)",firm_sql_id,character_id,inviter_character);
    inline Firm_Joined() {
        new id;if(cache_num_rows())cache_get_value_name_int(0,"firm_id",id);
        if(!Firm_SameSession(playerid,character_id,session)) {
            if(id==firm_sql_id)foreach(new member:Player)if(IsPlayerLogged(member) && Character[member][E_CHARACTER_ID]==character_id){Firm_LoadPlayer(member);break;}
            return 1;
        }
        new index=Firm_GetEnumID(firm_sql_id);
        if(id!=firm_sql_id || !Firm_IsActive(index))return SendClientMessage(playerid,COLOR_ERROR,"The invite expired, the firm filled up, or you already joined another firm.");
        Firm_ClearPlayer(playerid);PlayerFirm[playerid][E_PLAYER_FIRM_ID]=id;PlayerFirm[playerid][E_PLAYER_FIRM_RANK]=3;PlayerFirm[playerid][E_PLAYER_FIRM_PERMS]=Firm_GetDefaultRankPerms(3);
        Firm_Log(id,inviter_character,3,sprintf("Character %d accepted a firm invitation",character_id));
        Firm_SendMessage(id,sprintf("[Firm] %s joined as an Employee. Use /firmduty to work.",ReturnRPName(playerid)));return 1;
    }
    MySQL_TQueryInline(mysql,using inline Firm_Joined,query,"");return 1;
}

// /firmcar [assign/release] transfers an existing, personally purchased vehicle;
// it never creates free vehicles. Only the owner may release firm assets.
CMD:firmcar(playerid,params[]) {
    if(!Firm_PlayerCanAccess(playerid) || !IsPlayerInFirm(playerid))return Firm_SendAccessDenied(playerid);
    new index=Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);
    if(!Firm_IsActive(index) || !Firm_PlayerHasPerm(playerid,FIRM_PERM_VEHICLES))return SendClientMessage(playerid,COLOR_ERROR,"Your active firm rank needs vehicle permission.");
    if(GetPlayerState(playerid)!=PLAYER_STATE_DRIVER)return SendClientMessage(playerid,COLOR_ERROR,"Sit in the driver's seat of the vehicle first.");
    new action[16];if(sscanf(params,"s[16]",action) || (strcmp(action,"assign",true) && strcmp(action,"release",true)))return SendClientMessage(playerid,COLOR_INFO,"/firmcar [assign/release] - transfers ownership; no payment is made");
    new bool:release=!strcmp(action,"release",true),vehicleid=GetPlayerVehicleID(playerid),slot=Vehicle_GetEnumID(vehicleid);
    if(slot<0 || Vehicle[slot][E_VEHICLE_SQLID]<1)return SendClientMessage(playerid,COLOR_ERROR,"This is not a persistent vehicle.");
    new character_id=Character[playerid][E_CHARACTER_ID],firm_id=Firm[index][E_FIRM_ID],session=FirmSession[playerid],sqlid=Vehicle[slot][E_VEHICLE_SQLID];
    if(release) {
        if(Firm[index][E_FIRM_OWNER_CHAR_ID]!=character_id || Vehicle[slot][E_VEHICLE_TYPE]!=E_VEHICLE_TYPE_FIRM || Vehicle[slot][E_VEHICLE_OWNER]!=firm_id)return SendClientMessage(playerid,COLOR_ERROR,"Only the firm owner may release a vehicle owned by this firm.");
        if(Player_GetOwnedVehicles(playerid)>=Player_GetMaxOwnedVehicles(playerid))return SendClientMessage(playerid,COLOR_ERROR,"You have no free personal vehicle slots.");
    } else if(Vehicle[slot][E_VEHICLE_TYPE]!=E_VEHICLE_TYPE_PLAYER || Vehicle[slot][E_VEHICLE_OWNER]!=character_id)return SendClientMessage(playerid,COLOR_ERROR,"You may assign only your own personal vehicle.");
    new query[192];mysql_format(mysql,query,sizeof query,"SELECT COUNT(*) total FROM vehicles WHERE vehicle_type=%d AND vehicle_owner=%d",release?E_VEHICLE_TYPE_PLAYER:E_VEHICLE_TYPE_FIRM,release?character_id:firm_id);
    inline Firm_CarCapacity() {
        if(!Firm_SameSession(playerid,character_id,session) || !Firm_IsActive(index) || Firm[index][E_FIRM_ID]!=firm_id || PlayerFirm[playerid][E_PLAYER_FIRM_ID]!=firm_id || !Firm_PlayerHasPerm(playerid,FIRM_PERM_VEHICLES))return 1;
        if(GetPlayerState(playerid)!=PLAYER_STATE_DRIVER || GetPlayerVehicleID(playerid)!=vehicleid || Vehicle[slot][E_VEHICLE_SQLID]!=sqlid)return 1;
        new count;if(cache_num_rows())cache_get_value_name_int(0,"total",count);
        new cached=release?Player_GetOwnedVehicles(playerid):0;
        if(!release)for(new car;car<sizeof Vehicle;car++)if(Vehicle[car][E_VEHICLE_SQLID]>0 && Vehicle[car][E_VEHICLE_TYPE]==E_VEHICLE_TYPE_FIRM && Vehicle[car][E_VEHICLE_OWNER]==firm_id)cached++;
        if(max(count,cached)>=(release?Player_GetMaxOwnedVehicles(playerid):Firm[index][E_FIRM_VEHICLE_SLOTS]))return SendClientMessage(playerid,COLOR_ERROR,"The receiving owner has no free vehicle slots.");
        if(release) {
            if(Firm[index][E_FIRM_OWNER_CHAR_ID]!=character_id || Vehicle[slot][E_VEHICLE_TYPE]!=E_VEHICLE_TYPE_FIRM || Vehicle[slot][E_VEHICLE_OWNER]!=firm_id)return 1;
        } else if(Vehicle[slot][E_VEHICLE_TYPE]!=E_VEHICLE_TYPE_PLAYER || Vehicle[slot][E_VEHICLE_OWNER]!=character_id)return 1;
        Vehicle[slot][E_VEHICLE_TYPE]=release?E_VEHICLE_TYPE_PLAYER:E_VEHICLE_TYPE_FIRM;Vehicle[slot][E_VEHICLE_OWNER]=release?character_id:firm_id;Vehicle[slot][E_VEHICLE_SALE_PRICE]=0;
        Vehicle_WipeKeys(sqlid);
        mysql_format(mysql,query,sizeof query,"UPDATE vehicles SET vehicle_type=%d,vehicle_owner=%d,vehicle_sale_price=0 WHERE vehicle_sqlid=%d",Vehicle[slot][E_VEHICLE_TYPE],Vehicle[slot][E_VEHICLE_OWNER],sqlid);mysql_tquery(mysql,query);
        UsedCars_UpdateLabel(slot);
        Firm_Log(firm_id,character_id,8,sprintf("Vehicle SQL %d %s",sqlid,release?"released to the owner":"assigned from a personal vehicle"));
        return SendClientMessage(playerid,COLOR_INFO,"Vehicle ownership transferred. Keys were cleared; position, cargo and condition are unchanged.");
    }
    MySQL_TQueryInline(mysql,using inline Firm_CarCapacity,query,"");return 1;
}
