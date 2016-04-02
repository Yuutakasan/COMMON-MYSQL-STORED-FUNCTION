SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Table structure for tr_logs
-- ----------------------------
CREATE TABLE `tr_logs` (
  `id` int(18) unsigned NOT NULL auto_increment,
  `created_by` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `log_prj_name` varchar(255) NOT NULL,
  `log_apps_name` varchar(255) NOT NULL,
  `log_mod_name` varchar(255) NOT NULL,
  `log_mod_var` varchar(255) NOT NULL,
  `log_type` varchar(255) NOT NULL,
  `log_title` varchar(255) default NULL,
  `log_query` text,
  `log_text1` varchar(255) default NULL,
  `log_text2` varchar(255) default NULL,
  `log_text3` varchar(255) default NULL,
  `log_text4` varchar(255) default NULL,
  `log_text5` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_createdby` (`created_by`),
  KEY `idx_logmodname` (`log_mod_name`)
) DEFAULT CHARSET=utf8;

-- ----------------------------
-- Function structure for CMSF_FUNC_PUT_LOG
-- ----------------------------
DROP FUNCTION IF EXISTS `CMSF_FUNC_PUT_LOG`;
DELIMITER ;;
CREATE FUNCTION `CMSF_FUNC_PUT_LOG`(p_created_by varchar(255) , p_log_prj_name varchar(255) , p_log_apps_name varchar(255) , p_log_mod_name varchar(255) , p_log_mod_var varchar(255) , p_log_type varchar(255), p_log_title varchar(255) ,p_log_query text , p_log_text1 varchar(255) , p_log_text2 varchar(255) , p_log_text3 varchar(255) , p_log_text4 varchar(255) , p_log_text5 varchar(255)) RETURNS varchar(255) CHARSET utf8
BEGIN
/**
 * パラメータとして渡されたログを『tr_logs』に書き込むログ出力関数
 *
 * @package     CMSF
 * @category    CMSF_FUNC_PUT_LOG
 * @param       varchar(255) p_created_by    ログ作成者
 * @param       varchar(255) p_log_prj_name  プロジェクト名
 * @param       varchar(255) p_log_apps_name アプリケーション名
 * @param       varchar(255) p_log_mod_name  モジュール名
 * @param       varchar(255) p_log_mod_var   モジュールバージョン
 * @param       varchar(255) p_log_type      ログの種類
 * @param       varchar(255) p_log_title     処理名
 * @param       text         p_log_query     クエリ
 * @param       varchar(255) p_log_text1     ログ1
 * @param       varchar(255) p_log_text2     ログ2
 * @param       varchar(255) p_log_text3     ログ3
 * @param       varchar(255) p_log_text4     ログ4
 * @param       varchar(255) p_log_text5     ログ5
 * @return      text                         ログ出力処理結果
 * @example
 * @license     LGPL version 3 - http://www.gnu.org/licenses/lgpl.html
 * @copyright   2009 Yuusuke takagi <nya.takasan@gmail.com>
 * @link        http://sourceforge.jp/projects/cmsf/
 * @author      Yuusuke takagi <nya.takasan@gmail.com>
 * @version     $Revision: 0.0.1 2009/07/13 初期リリース Yuusuke takagi <nya.takasan@gmail.com>$
 * @version     $Revision: 0.0.2 2009/07/24 ログSQL文の最大長を2000文字から65555文字に変更 Yuusuke takagi <nya.takasan@gmail.com>$
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
 declare w_log_query                    text            default '';             /*  Query Log */

 /* ユーザー定義変数 */
 declare w_log_prj_name                 varchar(255)    default '';             /*  プロジェクト名 */
 declare w_log_apps_name                varchar(255)    default '';             /*  アプリケーション名 */
 declare w_log_mod_name                 varchar(255)    default '';             /*  モジュール名 */
 declare w_log_mod_var                  varchar(255)    default '';             /*  モジュールバージョン */
 declare w_log_type                     varchar(255)    default '';             /*  Log Type */
 declare w_log_title                    varchar(255)    default '';             /*  Log Title */
 declare w_log_text1                    varchar(255)    default '';             /*  Text Log1 */
 declare w_log_text2                    varchar(255)    default '';             /*  Text Log2 */
 declare w_log_text3                    varchar(255)    default '';             /*  Text Log3 */
 declare w_log_text4                    varchar(255)    default '';             /*  Text Log4 */
 declare w_log_text5                    varchar(255)    default '';             /*  Text Log5 */

 declare w_created_by                   varchar(255)    default '';             /*  データ作成者 */

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

 SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , w_log_mod_var , s_log_type_text
                                     , '処理名称' , w_log_query , 'ログ1' , 'ログ2' , 'ログ3' , 'ログ4' , 'ログ5' );

 ログ出力サンプル テキストログ

 SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , w_log_mod_var , s_log_type_text
                                     , '処理名称' , ''  , 'ログ1' , 'ログ2' , 'ログ3' , 'ログ4' , 'ログ5' );
*/
 declare s_log_prj_name                 varchar(255)    default 'CMSF';                         /*  プロジェクト名 */
 declare s_log_apps_name                varchar(255)    default 'COMMON';                       /*  アプリケーション名 */
 declare s_log_mod_name                 varchar(255)    default 'CMSF_FUNC_PUT_LOG';            /*  モジュール名 */
 declare s_log_mod_var                  varchar(255)    default '0.0.2';                        /*  モジュールバージョン */

 declare s_log_created_by               varchar(255)    default 'SYSTEM';               /*  ログ作成者 */

 declare s_log_type_insert              varchar(255)    default 'INSERT';               /*  ログタイプ:INSERT  */
 declare s_log_type_select              varchar(255)    default 'SELECT';               /*  ログタイプ:SELECT  */
 declare s_log_type_update              varchar(255)    default 'UPDATE';               /*  ログタイプ:UPDATE */
 declare s_log_type_delete              varchar(255)    default 'DELETE';               /*  ログタイプ:DELETE */

 declare s_log_type_debug               varchar(255)    default 'DEBUG';                 /*  ログタイプ:DEBUG */
 declare s_log_type_info                varchar(255)    default 'INFO';                  /*  ログタイプ:INFO */
 declare s_log_type_warn                varchar(255)    default 'WARN';                  /*  ログタイプ:WARN */
 declare s_log_type_error               varchar(255)    default 'ERROR';                 /*  ログタイプ:ERROR */
 declare s_log_type_fatal               varchar(255)    default 'FATAL';                 /*  ログタイプ:FATAL */
 declare s_log_type_text                varchar(255)    default 'TEXT';                  /*  ログタイプ:TEXT */

 declare s_log_type_tmp                 varchar(255)    default 'TEMPORARY';            /*  ログタイプ:TEMPORARY */

 /* ユーザー定義定数 */
 declare s_ok                           varchar(255)    default 'OK';                   /*  デバッグ機能無効時出力結果 */

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
 SET w_created_by        = p_created_by;
 SET w_log_prj_name      = p_log_prj_name;
 SET w_log_apps_name     = p_log_apps_name;
 SET w_log_mod_name      = p_log_mod_name;
 SET w_log_mod_var       = p_log_mod_var;
 SET w_log_type          = p_log_type;
 SET w_log_title         = p_log_title;
 SET w_log_query         = p_log_query;
 SET w_log_text1         = p_log_text1;
 SET w_log_text2         = p_log_text2;
 SET w_log_text3         = p_log_text3;
 SET w_log_text4         = p_log_text4;
 SET w_log_text5         = p_log_text5;

 /*  ログ出力*/
 IF( s_log_flg = 1 ) THEN
        SET w_result =  CONCAT( '1.0 初期処理 パラメータ:' , p_created_by , ',' , p_log_prj_name , ',' , p_log_apps_name , ',' ,p_log_mod_name , ',' , w_log_mod_var , ',' , p_log_type , ',' , p_log_title , ',' ,
                            p_log_text1 , ',' , p_log_text2 , ',' , p_log_text3 , ',' , p_log_text4 , ',' , p_log_text5 );
 END IF;


 /* 2.1.1 ログ追加処理 */
  INSERT INTO tr_logs(
    created_by,
    created_at,
    log_prj_name,
    log_apps_name,
    log_mod_name,
    log_mod_var,
    log_type,
    log_title,
    log_query,
    log_text1,
    log_text2,
    log_text3,
    log_text4,
    log_text5
  )
  VALUES
  (
    w_created_by,
    SYSDATE(),
    w_log_prj_name,
    w_log_apps_name,
    w_log_mod_name,
    w_log_mod_var,
    w_log_type,
    w_log_title,
    w_log_query,
    w_log_text1,
    w_log_text2,
    w_log_text3,
    w_log_text4,
    w_log_text5
  );


 IF( s_log_flg = 0 ) THEN
   SET w_result = s_ok;
 END IF;

/*  ログ出力*/
IF( s_log_flg = 1 ) THEN

      SET w_log_query = CONCAT(
"INSERT INTO tr_logs("
,"created_by,"
,"created_at,"
,"log_prj_name,"
,"log_apps_name,"
,"log_mod_name,"
,"log_mod_var,"
,"log_type,"
,"log_title,"
,"log_query,"
,"log_text1,"
,"log_text2,"
,"log_text3,"
,"log_text4,"
,"log_text5,"
,"),"
,"VALUES,"
,"(,"
,"'" , w_created_by , "'"
,"'" , SYSDATE() , "'"
,"'" , w_log_prj_name , "'"
,"'" , w_log_apps_name , "'"
,"'" , w_log_mod_name , "'"
,"'" , w_log_mod_var , "'"
,"'" , w_log_type , "'"
,"'" , w_log_title , "'"
,"'" , w_log_query , "'"
,"'" , w_log_text1 , "'"
,"'" , w_log_text2 , "'"
,"'" , w_log_text3 , "'"
,"'" , w_log_text4 , "'"
,"'" , w_log_text5 , "'"
,");"
      );

END IF;

return w_result;

END;;
DELIMITER ;

