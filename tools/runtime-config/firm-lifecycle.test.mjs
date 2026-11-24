// Database checks for the complete firm registration/member/closure path.
// Called only by the integration runner after its empty-test-database guard.
export async function checkFirmLifecycle(db,check,connect) {
  const [account]=await db.query("SELECT account_id FROM accounts WHERE account_name='RuntimeAdmin'");
  const characters=[];
  for(let i=0;i<6;i++) {
    const inserted=await db.query('INSERT INTO characters(account_id,player_name) VALUES(?,?)',[account.account_id,'Firm_Test_'+i]);characters.push(Number(inserted.insertId));
  }
  const [owner,other,first,second,third,fault]=characters;
  const call=async(connection,sql,args)=>{
    const result=await connection.query(sql,args);
    const row=result.flat().find(value=>value&&typeof value==='object'&&Object.hasOwn(value,'firm_id'));
    if(!row)throw Error('Firm routine returned no result');return row;
  };
  let rejected=await call(db,"CALL orp_firm_register(?,'Test Motors','MTR',1,10,15,250)",[owner]);
  check(!rejected.firm_id&&rejected.result==='license','firm registration explains the missing professional licence and writes no partial firm');
  await db.query("INSERT INTO character_licenses(character_id,license_type,issued_by,issued_at) VALUES(?,'mechanic',0,NOW())",[owner]);
  const [licence]=await db.query('SELECT issued_at FROM character_licenses WHERE character_id=?',[owner]);check(Boolean(licence.issued_at),'professional business registration stores a valid datetime');
  const registered=await call(db,"CALL orp_firm_register(?,'Test Motors','MTR',1,10,15,250)",[owner]);const firmId=Number(registered.firm_id);
  const [paid]=await db.query('SELECT player_cash FROM characters WHERE player_id=?',[owner]);check(paid.player_cash===250,'firm fee is debited in the registration transaction');
  const [membership]=await db.query('SELECT firm_id,firm_rank,firm_permissions FROM firm_members WHERE character_id=?',[owner]);
  check(firmId>0&&membership.firm_id===firmId&&membership.firm_rank===1&&membership.firm_permissions===255,'firm creation atomically creates an owner with all permissions');
  rejected=await call(db,"CALL orp_firm_register(?,'Another Firm','OTHER',7,10,15,0)",[owner]);check(!rejected.firm_id,'an owner cannot register a second active firm');
  rejected=await call(db,"CALL orp_firm_register(?,'Name Conflict','MTR',7,10,15,0)",[other]);check(!rejected.firm_id&&rejected.result==='duplicate','active firm abbreviations are unique');
  const used=await call(db,"CALL orp_firm_register(?,'Used Cars','USED',7,10,15,0)",[other]);check(used.firm_id>0,'used-car registration has a path without a professional licence');
  rejected=await call(db,'CALL orp_firm_join(?,?,?)',[firmId,first,third]);check(!rejected.firm_id&&rejected.result==='permission','firm invitations recheck current inviter authority in the transaction');
  await db.query('UPDATE firms SET firm_member_slots=2 WHERE firm_id=?',[firmId]);
  const connections=await Promise.all([connect(),connect()]);let concurrent;
  try {concurrent=await Promise.all(connections.map((connection,i)=>call(connection,'CALL orp_firm_join(?,?,?)',[firmId,i?second:first,owner])));}finally{await Promise.all(connections.map(c=>c.end()));}
  const joined=concurrent.filter(row=>row.firm_id===firmId);
  check(joined.length===1,'two concurrent accepted invites cannot overfill the last member slot');
  const [count]=await db.query('SELECT COUNT(*) total FROM firm_members WHERE firm_id=?',[firmId]);check(Number(count.total)===2,'firm capacity includes the owner and committed members');
  const [employee]=await db.query('SELECT character_id,firm_rank,firm_permissions FROM firm_members WHERE firm_id=? AND character_id<>?',[firmId,owner]);
  check(employee.firm_rank===3&&employee.firm_permissions===16,'accepted employees receive field tools without management permissions');
  rejected=await call(db,'CALL orp_firm_join(?,?,?)',[Number(used.firm_id),employee.character_id,other]);check(!rejected.firm_id&&rejected.result==='membership','one character cannot join two firms');
  rejected=await call(db,'CALL orp_firm_close(?,?)',[firmId,employee.character_id]);check(!rejected.firm_id&&rejected.result==='owner','employees cannot close the firm');
  await db.query('UPDATE firms SET firm_bank=100 WHERE firm_id=?',[firmId]);
  rejected=await call(db,'CALL orp_firm_close(?,?)',[firmId,owner]);check(!rejected.firm_id&&rejected.result==='bank','closure requires the owner to withdraw remaining funds');
  await db.query('UPDATE firms SET firm_bank=0 WHERE firm_id=?',[firmId]);
  const car=await db.query('INSERT INTO vehicles(vehicle_modelid,vehicle_type,vehicle_owner,vehicle_pos_x,vehicle_pos_y,vehicle_pos_z,vehicle_pos_a) VALUES(420,6,?,100,100,20,0)',[firmId]);
  rejected=await call(db,'CALL orp_firm_close(?,?)',[firmId,owner]);check(!rejected.firm_id&&rejected.result==='vehicles','ordinary firm vehicles must be released before closure');
  await db.query('DELETE FROM vehicles WHERE vehicle_sqlid=?',[Number(car.insertId)]);
  const closed=await call(db,'CALL orp_firm_close(?,?)',[firmId,owner]);
  const [remaining]=await db.query('SELECT COUNT(*) total FROM firm_members WHERE firm_id=?',[firmId]);
  check(closed.firm_id===firmId&&Number(remaining.total)===0,'closure removes memberships and closes the firm together');
  rejected=await call(db,'CALL orp_firm_join(?,?,?)',[firmId,third,owner]);check(!rejected.firm_id&&rejected.result==='inactive','late invites cannot revive a closed firm');
  const reused=await call(db,"CALL orp_firm_register(?,'Test Motors','MTR',7,10,15,0)",[owner]);check(reused.firm_id>0&&reused.firm_id!==firmId,'a former owner can start again and reuse a closed firm name and abbreviation');
  await db.query(`CREATE TRIGGER orp_test_firm_failure BEFORE INSERT ON firm_members FOR EACH ROW BEGIN IF NEW.character_id=${fault} THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='injected test failure'; END IF; END`);
  try {
    rejected=await call(db,"CALL orp_firm_register(?,'Fault Firm','FAULT',7,10,15,100)",[fault]);
    const [partial]=await db.query("SELECT COUNT(*) total FROM firms WHERE firm_abbrev='FAULT'");
    const [faultCash]=await db.query('SELECT player_cash FROM characters WHERE player_id=?',[fault]);
    check(!rejected.firm_id&&Number(partial.total)===0&&faultCash.player_cash===500,'an owner-membership failure rolls back both firm and cash debit');
  }finally{await db.query('DROP TRIGGER orp_test_firm_failure');}
  for(const id of [Number(used.firm_id),Number(reused.firm_id)])await call(db,'CALL orp_firm_close(?,?)',[id,id===Number(used.firm_id)?other:owner]);
  await db.query('DELETE FROM firms WHERE firm_owner_char_id IN ('+characters.map(()=>'?').join(',')+')',characters);
  await db.query('DELETE FROM character_licenses WHERE character_id IN ('+characters.map(()=>'?').join(',')+')',characters);
  await db.query('DELETE FROM characters WHERE player_id IN ('+characters.map(()=>'?').join(',')+')',characters);
}
