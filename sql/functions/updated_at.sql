CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t record;
BEGIN
    FOR t IN 
        SELECT * FROM information_schema.columns
        WHERE column_name = 'updated_at'
    LOOP
        EXECUTE format('CREATE TRIGGER set_timestamp
                        BEFORE UPDATE ON %I
                        FOR EACH ROW
                        EXECUTE PROCEDURE trigger_set_timestamp();',
                        t.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;