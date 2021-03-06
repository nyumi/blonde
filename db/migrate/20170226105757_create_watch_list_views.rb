class CreateWatchListViews < ActiveRecord::Migration[5.0]
  TABLE_NAME = "watch_list_views"

  def up
    execute create_view_sql
  end

  def down
    execute drop_view_sql
  end

  def create_view_sql
    db_adapter = ActiveRecord::Base.connection_config[:adapter]

    case db_adapter
      when 'postgresql' then
        create_postgresql_view_sql
      else
        raise Exception, "Not Support Data Base [#{db_adapter}]"
    end
  end

  def drop_view_sql
    "DROP VIEW #{TABLE_NAME}"
  end

  def create_postgresql_view_sql
    "
    DROP VIEW IF EXISTS  #{TABLE_NAME};
    CREATE VIEW #{TABLE_NAME}
    as
      SELECT
        bk.title,
        bk.author,
        bk.publish_date,
        ppbk.price as pp_price,
        ppbk.point as pp_point,
        kdbk.price as kd_price,
        kdbk.published_date as kd_published_date,
        kdbk.point as kd_point
      FROM books bk
        LEFT OUTER JOIN paper_books ppbk
            ON bk.id = ppbk.book_id
        LEFT OUTER JOIN kindle_books kdbk
            ON bk.id = kdbk.book_id
    ;
  "
  end
end
