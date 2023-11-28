-- добавить поиск схемы по умолчанию в БД
ALTER DATABASE test SET search_path = pract_functions, public;
SHOW SEARCH_PATH;

CREATE OR REPLACE FUNCTION sales_changed()
RETURNS trigger AS
$$
    -- Триггерная функция для заполнения витрины (таблица: good_sum_mart)
DECLARE
    v_good_id integer;
    v_delta_sales_qty integer;
    v_good_name  varchar(63);
    v_delta_sum_sale numeric(16,2);
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_good_id = old.good_id;
        v_delta_sales_qty = -1 * old.sales_qty;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_good_id = old.good_id;
        v_delta_sales_qty = new.sales_qty - OLD.sales_qty;
    ELSIF (TG_OP = 'INSERT') THEN
        v_good_id = new.good_id;
        v_delta_sales_qty = new.sales_qty;
    end if;

    -- сохраняем наименование товара и изменения оборота
    SELECT g.good_name, sum(g.good_price * v_delta_sales_qty)
    into v_good_name, v_delta_sum_sale
    FROM goods g
    where g.goods_id=v_good_id
    GROUP BY G.good_name;

    raise notice '% - good_name=%, v_delta_sum_sale: %', TG_OP, v_good_name, v_delta_sum_sale;

    <<insert_update>>
    BEGIN
        UPDATE good_sum_mart
        SET sum_sale = sum_sale + v_delta_sum_sale
        WHERE good_name = v_good_name;

        EXIT insert_update WHEN found;

        INSERT INTO good_sum_mart(good_name, sum_sale)
        VALUES (v_good_name, v_delta_sum_sale);
    END;

    -- убираем запись по заданному товару если сумма <=0
    DELETE FROM good_sum_mart WHERE good_name = v_good_name and sum_sale<=0;

    RETURN NULL;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER tr_sales_changed
AFTER INSERT OR UPDATE OR DELETE ON sales
FOR EACH ROW EXECUTE PROCEDURE sales_changed();
