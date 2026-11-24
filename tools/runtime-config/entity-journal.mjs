// Produce CLI-compatible MariaDB triggers from trusted, whitelisted metadata.
export function generateEntityJournal(entityTypes,schemaVersion=2) {
  const quote=value=>"'"+String(value).replaceAll("'","''")+"'";
  const identifier=value=>'`'+value+'`';
  let sql='-- Generated entity change journal. Requires MariaDB TRIGGER privilege.\nDELIMITER //\n';
  for(const [type,definition]of Object.entries(entityTypes))for(const operation of ['INSERT','UPDATE','DELETE']) {
    const record=prefix=>'JSON_OBJECT('+Object.entries(definition.fields).map(([key,field])=>quote(key)+',COALESCE('+prefix+'.'+identifier(key)+','+(field.text?quote(''):0)+')').join(',')+')';
    const snapshot=(prefix,empty=false)=>'JSON_OBJECT('+quote('entities')+',JSON_ARRAY(JSON_OBJECT('+quote('type')+','+quote(type)+','+quote('id')+','+prefix+'.'+identifier(definition.id)+','+quote('record')+','+(empty?'NULL':record(prefix))+')))';
    const prefix=operation==='DELETE'?'OLD':'NEW';
    const changed=operation==='UPDATE'?' AND ('+Object.keys(definition.fields).map(key=>'NOT (NEW.'+identifier(key)+' <=> OLD.'+identifier(key)+')').join(' OR ')+')':'';
    sql+=`DROP TRIGGER IF EXISTS ${identifier('orp_runtime_'+type+'_'+operation.toLowerCase())}//
CREATE TRIGGER ${identifier('orp_runtime_'+type+'_'+operation.toLowerCase())} AFTER ${operation} ON ${identifier(definition.table)} FOR EACH ROW
BEGIN
  DECLARE v_revision INT UNSIGNED;
  IF COALESCE(@orp_config_write,0)=0${changed} THEN
    UPDATE runtime_config_state SET revision=revision+1,last_error='' WHERE id=1 AND revision<2147483000;
    IF ROW_COUNT()<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Runtime configuration state unavailable or revision limit reached'; END IF;
    SELECT revision INTO v_revision FROM runtime_config_state WHERE id=1;
    INSERT INTO runtime_entity_changes(revision,entity_type,entity_id,operation) VALUES(v_revision,${quote(type)},${prefix}.${identifier(definition.id)},${quote(operation==='DELETE'?'delete':'upsert')});
    INSERT INTO runtime_config_audit(revision,account_id,account_name,source,description,before_json,after_json,created_at) VALUES(v_revision,0,'Database','database',${quote(operation+' '+type+' from database writer')},${snapshot(operation==='INSERT'?'NEW':'OLD',operation==='INSERT')},${snapshot(operation==='DELETE'?'OLD':'NEW',operation==='DELETE')},UNIX_TIMESTAMP());
  END IF;
END//
`;
  }
  return sql+"DELIMITER ;\nUPDATE runtime_config_state SET schema_version="+schemaVersion+" WHERE id=1;\n";
}
