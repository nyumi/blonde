class CreateWatchListViews < ActiveRecord::Migration[5.0]
  TABLE_NAME = "watch_list_views"

  # def change
  #   create_table :watch_lists do |t|
  #
  #     t.timestamps
  #   end
  # end


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
    create or replace view #{TABLE_NAME}
    as
      SELECT
        bk.title,
        bk.author,
        ppbk.price as pp_price,
        ppbk.published_date as pp_published_date,
        ppbk.point as pppoint,
        kdbk.price as kd_price,
        kdbk.published_date as kd_published_date,
        kdbk.point as kd_point
      FROM books bk
        INNER JOIN paper_books ppbk
            ON bk.id = ppbk.book_id
        INNER JOIN kindle_books kdbk
            ON bk.id = kdbk.book_id
    ;
  "
  end

end
