require_relative "20170226105757_create_watch_list_views"
class AddUserIdToWatchListViews < ActiveRecord::Migration[5.0]
  TABLE_NAME = "watch_list_views"

  def up
    execute create_view_sql
  end

  def down
    CreateWatchListViews.up

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


  def create_postgresql_view_sql
    # "#{CreateWatchListViews.down} if exists;"

    "
    DROP VIEW IF EXISTS  #{TABLE_NAME};
    CREATE OR REPLACE VIEW #{TABLE_NAME}
    as
      SELECT
        bk.title,
        bk.author,
        bk.publish_date,
        bk.user_id,
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
