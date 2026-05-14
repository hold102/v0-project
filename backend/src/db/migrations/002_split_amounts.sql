-- 002_split_amounts.sql
-- Migration: Support unequal expense splits.
--
-- Adds a nullable per-member `amount` column to expense_split_members.
--   NULL  -> participate in an equal split (original behavior, backwards compatible)
--   value -> that user's exact dollar share of the expense
--
-- Also replaces sync_full_database to read the optional `splitAmounts` map
-- from each expense JSONB payload.

ALTER TABLE expense_split_members
  ADD COLUMN IF NOT EXISTS amount NUMERIC(10,2) NULL;

CREATE OR REPLACE FUNCTION sync_full_database(
    p_current_user_id TEXT,
    p_users JSONB,
    p_accounts JSONB,
    p_groups JSONB
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    group_record RECORD;
    expense_record RECORD;
BEGIN
    DELETE FROM expense_split_members WHERE true;
    DELETE FROM expenses WHERE true;
    DELETE FROM group_members WHERE true;
    DELETE FROM groups_table WHERE true;
    DELETE FROM accounts WHERE true;
    DELETE FROM app_state WHERE true;
    DELETE FROM users WHERE true;

    INSERT INTO users (id, name, avatar, email)
    SELECT x.id, x.name, COALESCE(x.avatar, '👤'), x.email
    FROM jsonb_to_recordset(p_users) AS x(id TEXT, name TEXT, avatar TEXT, email TEXT);

    INSERT INTO app_state (id, current_user_id) VALUES (1, p_current_user_id);

    IF p_accounts IS NOT NULL AND jsonb_array_length(p_accounts) > 0 THEN
        INSERT INTO accounts (user_id, email, password_hash, salt, created_at)
        SELECT x."userId", x.email, x."passwordHash", x.salt, x."createdAt"
        FROM jsonb_to_recordset(p_accounts) AS x(
            "userId" TEXT, email TEXT, "passwordHash" TEXT, salt TEXT, "createdAt" TEXT
        );
    END IF;

    IF p_groups IS NOT NULL AND jsonb_array_length(p_groups) > 0 THEN
        INSERT INTO groups_table (id, name, emoji, created_at)
        SELECT x.id, x.name, x.emoji, x."createdAt"
        FROM jsonb_to_recordset(p_groups) AS x(
            id TEXT, name TEXT, emoji TEXT, "createdAt" TEXT
        );

        FOR group_record IN
            SELECT * FROM jsonb_to_recordset(p_groups) AS x(
                id TEXT, members JSONB, expenses JSONB
            )
        LOOP
            IF group_record.members IS NOT NULL AND jsonb_array_length(group_record.members) > 0 THEN
                INSERT INTO group_members (group_id, user_id)
                SELECT group_record.id, member_data->>'id'
                FROM jsonb_array_elements(group_record.members) AS member_data;
            END IF;

            IF group_record.expenses IS NOT NULL AND jsonb_array_length(group_record.expenses) > 0 THEN
                INSERT INTO expenses (id, description, amount, paid_by, category, date, group_id)
                SELECT
                    e_data->>'id',
                    e_data->>'description',
                    (e_data->>'amount')::NUMERIC,
                    e_data->>'paidBy',
                    e_data->>'category',
                    e_data->>'date',
                    group_record.id
                FROM jsonb_array_elements(group_record.expenses) AS e_data;

                FOR expense_record IN
                    SELECT
                        e_data->>'id' AS exp_id,
                        e_data->'splitBetween' AS split_data,
                        e_data->'splitAmounts' AS amounts_data
                    FROM jsonb_array_elements(group_record.expenses) AS e_data
                LOOP
                    IF expense_record.split_data IS NOT NULL AND
                       jsonb_array_length(expense_record.split_data) > 0 THEN
                        -- Insert each split member; pull the per-user amount from splitAmounts
                        -- if present, otherwise NULL (= participate in equal split).
                        INSERT INTO expense_split_members (expense_id, user_id, amount)
                        SELECT
                            expense_record.exp_id,
                            split_user_id,
                            CASE
                                WHEN expense_record.amounts_data IS NOT NULL
                                     AND expense_record.amounts_data ? split_user_id
                                THEN (expense_record.amounts_data->>split_user_id)::NUMERIC
                                ELSE NULL
                            END
                        FROM jsonb_array_elements_text(expense_record.split_data) AS split_user_id;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    END IF;
END;
$$;
