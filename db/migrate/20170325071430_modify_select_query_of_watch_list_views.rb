require_relative "20170319141700_modify_watch_list_views"
class ModifySelectQueryOfWatchListViews < ActiveRecord::Migration[5.0]
  TABLE_NAME = "watch_list_views"

  def up
    execute create_view_sql
  end

  def down
    ModifyWatchListViews.new.down
    ModifyWatchListViews.new.up
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
    "
    DROP VIEW IF EXISTS  #{TABLE_NAME};
    CREATE VIEW #{TABLE_NAME}
    as
        SELECT
          bk.id,
          bk.title,
          bk.author,
          bk.publish_date,
          bk.user_id,
          pphis.price as pp_price,
          pphis.point as pp_point,
          ppbk.detail_link as pp_link,
          kinhis.price as kd_price,
          kdbk.published_date as kd_published_date,
          kinhis.point as kd_point,
          kdbk.detail_link as kd_link,
          bk.img
        FROM books as bk
          LEFT OUTER JOIN paper_books ppbk
              ON bk.id = ppbk.book_id
          LEFT OUTER JOIN kindle_books kdbk
              ON bk.id = kdbk.book_id
          LEFT OUTER JOIN (
              SELECT
                book_id ,
                price,
                point,
                created_at
                from paper_histories as a
                where id = (
                    select id from paper_histories as b
                    where a.book_id = b.book_id order by created_at desc limit 1)
           ) as pphis
              ON bk.id = pphis.book_id
          LEFT OUTER JOIN (
              SELECT
                book_id ,
                price,
                point,
                created_at
                from kindle_histories as a
                where id = (
                    select id from kindle_histories as b
                    where a.book_id = b.book_id order by created_at desc limit 1)
          ) as kinhis
              ON bk.id = kinhis.book_id

    ;
  "
  end
end
