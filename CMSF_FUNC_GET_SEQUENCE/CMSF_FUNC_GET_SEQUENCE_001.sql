SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Table structure for ms_sequence
-- ----------------------------
DROP TABLE IF EXISTS `ms_sequence`;
CREATE TABLE `ms_sequence` (
  `id` int(18) NOT NULL auto_increment,
  `created_by` varchar(20) default NULL,
  `created_at` timestamp NULL default NULL,
  `updated_by` varchar(20) default NULL,
  `updated_at` timestamp NULL default NULL on update CURRENT_TIMESTAMP,
  `name` varchar(255) NOT NULL,
  `sequence_no` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `idx_name` (`name`)
) DEFAULT CHARSET=utf8;

-- ----------------------------
-- Function structure for CMSF_FUNC_GET_SEQUENCE
-- ----------------------------
DROP FUNCTION IF EXISTS `CMSF_FUNC_GET_SEQUENCE`;
DELIMITER ;;
CREATE FUNCTION `CMSF_FUNC_GET_SEQUENCE`(p_sequence_kind varchar(255)) RETURNS text CHARSET utf8
BEGIN
/**
 * パラメータを含むシーケンス番号を返す関数
 *
 * @package     CMSF
 * @category    CMSF_FUNC_GET_SEQUENCE
 * @param       text         p_sequence_kind  シーケンス採番用パラメータ
 * @return      text                          CSVデータ
 * @example
 * @license     LGPL version 3 - http://www.gnu.org/licenses/lgpl.html
 * @copyright   2009 Yuusuke takagi <nya.takasan@gmail.com>
 * @link        http://sourceforge.jp/projects/cmsf/
 * @author      Yuusuke takagi <nya.takasan@gmail.com>
 * @version     $Revision: 0.0.1 2009/10/13 初期リリース Yuusuke takagi <nya.takasan@gmail.com>$
 * @since
 * @see
 * @require     MYSQL 5.0.0 or higther
 */
 /*------------------------------------------------------
    変数定義
 -------------------------------------------------------*/
 declare w_result                       text            default '';             /*  変換文字列 */

 /* ログ関連 */
 declare w_log_result                   varchar(255)    default '';             /* Log 結果 */
 declare w_log_query                    text            default '';             /* Query Log */
 declare w_start_time                   DATETIME        default NULL;           /* 実行開始時間 */
 declare w_start_unixtime               int(18)         default NULL;           /* 実行開始時間 */
 declare w_end_time                     DATETIME        default NULL;           /* 実行終了時間 */
 declare w_end_unixtime                 int(18)         default NULL;           /* 実行終了時間 */
 declare w_exection_time                int(18)         default NULL;           /* 実行時間 */


 /* ユーザー定義変数 */
 declare w_sequence_kind                varchar(255)    default NULL;           /*  文字列 */

 /*------------------------------------------------------
    ユーザ例外定義
  -------------------------------------------------------*/

 /*------------------------------------------------------
    定数定義
 -------------------------------------------------------*/
 declare s_empty_string                 varchar(255)    default '';             /*  空文字 */
 declare s_true                         varchar(255)    default 1;              /*  TRUE  FLG*/
 declare s_false                        varchar(255)    default 0;              /*  FALSE FLG */

 /* ログ関連 */
 declare s_log_flg                      int(1)          default 0;              /*  エラー処理フラグ ON:1 OFF:0 */

/*
 ログ出力サンプル SQLログ

 SET w_log_query = CONCAT(
 "    SQL"
 );

 SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
                                     , '処理名称' , w_log_query , 'ログ1' , 'ログ2' , 'ログ3' , 'ログ4' , 'ログ5' );

 ログ出力サンプル テキストログ

 SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
                                     , '処理名称' , s_empty_string  , 'ログ1' , 'ログ2' , 'ログ3' , 'ログ4' , 'ログ5' );
*/
 declare s_log_prj_name                 varchar(255)    default 'CMSF';                       /*  プロジェクト名 */
 declare s_log_apps_name                varchar(255)    default 'COMMON';                     /*  アプリケーション名 */
 declare s_log_mod_name                 varchar(255)    default 'CMSF_FUNC_GET_SEQUENCE';     /*  モジュール名 */
 declare s_log_prg_var                  varchar(255)    default '0.0.1';                      /*  モジュールバージョン */

 declare s_log_created_by               varchar(255)    default 'SYSTEM';               /*  ログ作成者 */

 declare s_log_type_insert              varchar(255)    default 'INSERT';               /*  ログタイプ:INSERT  */
 declare s_log_type_select              varchar(255)    default 'SELECT';               /*  ログタイプ:SELECT  */
 declare s_log_type_update              varchar(255)    default 'UPDATE';               /*  ログタイプ:UPDATE */
 declare s_log_type_delete              varchar(255)    default 'DELETE';               /*  ログタイプ:DELETE */

 declare s_log_type_text                varchar(255)    default 'TEXT';                 /*  ログタイプ:TEXT */

 declare s_log_type_error               varchar(255)    default 'ERROR';                /*  ログタイプ:ERROR */

 declare s_log_type_tmp                 varchar(255)    default 'TEMPORARY';            /*  ログタイプ:TEMPORARY */

 /* ユーザー定義定数 */
 declare s_sequence_length              int(4)          default 18;                     /*  シーケンス番号の桁数 */

 /*------------------------------------------------------
    カーソル定義
 -------------------------------------------------------*/
  /*--------------------------------------------
   カーソル説明
  ---------------------------------------------*/

 /*----------------------------------------------------------
   処理定義
 -----------------------------------------------------------*/
 /* 1.0 初期処理*/
 SET w_sequence_kind        = p_sequence_kind;
 SET @w_sequence_no         = NULL;

 /*  ログ出力*/
 IF( s_log_flg = 1 ) THEN
        SET w_start_time     = SYSDATE();
        SET w_start_unixtime = UNIX_TIMESTAMP(w_start_time);

        SET w_log_result =  CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
                                             , CONCAT( '1.0 初期処理 パラメータ:' , p_sequence_kind ) , s_empty_string , CONCAT( '開始時間:' , w_start_time ) , s_empty_string , s_empty_string , s_empty_string , s_empty_string );
  END IF;

 /* 2.1.1 シーケンスUPDATE処理 */
 UPDATE ms_sequence
    SET ms_sequence.id               = NULL ,
        ms_sequence.updated_at       = NOW() ,
        ms_sequence.created_by       = s_log_created_by ,
        ms_sequence.sequence_no      = @w_sequence_no := ms_sequence.sequence_no + 1
  WHERE ms_sequence.name             = w_sequence_kind;

 /*  ログ出力*/
 IF( s_log_flg = 1 ) THEN

 /* ログ出力サンプル SQLログの場合 */
 SET w_log_query = CONCAT(
   "UPDATE ms_sequence"
  ," SET ms_sequence.id              = NULL, "
  ,"     ms_sequence.updated_at      = " , NOW()
  ,"     ms_sequence.created_by      = " , s_log_created_by
  ,"     ms_sequence.sequence_no     = " , @w_sequence_no  , " := ms_sequence.sequence_no + 1 "
  ," WHERE ms_sequence.sequence_name = " , w_sequence_kind , ";"
 );

 /* UPDATE分の場合 */
 SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_update
                                     , '2.1.1 シーケンスUPDATE処理 ' , w_log_query , CONCAT( '更新件数:' ,ROW_COUNT()) , s_empty_string , s_empty_string , s_empty_string , s_empty_string );

 END IF;

 /* 2.1.3 シーケンス追加処理 */
 IF( @w_sequence_no is null ) THEN

   SET @w_sequence_no = 1;

   INSERT INTO ms_sequence ( id   , created_at , created_by       , updated_at , updated_by       , name            , sequence_no )
                  VALUES   ( NULL , NOW()      , s_log_created_by , NOW()      , s_log_created_by , w_sequence_kind , @w_sequence_no );

   /*  ログ出力*/
   IF( s_log_flg = 1 ) THEN

   /* ログ出力サンプル SQLログの場合 */
   SET w_log_query = CONCAT(
    "INSERT INTO ms_sequence ( id   , created_at  ,  created_by        , updated_at ,   updated_by         , name                , sequence_no )"
   ,"               VALUES   ( NULL , ",NOW(),   ",",s_log_created_by,",",NOW()   ,",", s_log_created_by ,",", w_sequence_kind ,",", @w_sequence_no ,")"
   );

   /* UPDATE分の場合 */
   SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_update
                                       , '2.1.1 シーケンス追加処理 ' , w_log_query , CONCAT( '挿入件数:' ,ROW_COUNT()) , s_empty_string , s_empty_string , s_empty_string , s_empty_string );

   END IF;

 END IF;


 /* 2.1.2 シーケンス番号取得 */
 SET    w_result  = CONCAT( p_sequence_kind , LPAD( @w_sequence_no , s_sequence_length , '0' ) );

 /*  ログ出力*/
 IF( s_log_flg = 1 ) THEN

 /* UPDATE分の場合 */
 SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
                                     , '2.1.2 シーケンス番号取得' , w_log_query , w_result , s_empty_string , s_empty_string , s_empty_string , s_empty_string );

 END IF;

 /*  ログ出力処理  */
 IF( s_log_flg = 1 ) THEN

        SET w_end_time      = SYSDATE();
        SET w_end_unixtime  = UNIX_TIMESTAMP(w_end_time);
        SET w_exection_time = (w_end_time - w_start_time);

        SET w_log_result =  CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
                                             , CONCAT( '9.9.9 処理完了 :' , w_result  ) , s_empty_string , CONCAT( '開始時間:' , w_start_time ) , CONCAT( '終了時間:' , w_end_time ) , CONCAT( '実行時間:' , w_exection_time , '秒') , s_empty_string , s_empty_string );
 END IF;

 return w_result;

END;;
DELIMITER ;
