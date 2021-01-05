SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for tr_logs
-- ----------------------------
DROP TABLE IF EXISTS `tr_logs`;
CREATE TABLE `tr_logs`  (
  `id` int(18) UNSIGNED NOT NULL AUTO_INCREMENT,
  `created_by` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `log_prj_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `log_apps_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `log_mod_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `log_mod_var` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `log_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `log_title` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `log_query` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL,
  `log_text1` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `log_text2` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `log_text3` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `log_text4` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `log_text5` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_log_mod_name`(`log_mod_name`) USING BTREE,
  INDEX `idx_log_title`(`log_title`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '実行ログテーブル' KEY_BLOCK_SIZE = 8 ROW_FORMAT = COMPRESSED TABLESPACE = `innodb_file_per_table`;

-- ----------------------------
-- Records of tr_logs
-- ----------------------------
INSERT INTO `tr_logs` VALUES (1, '', '2021-01-06 03:43:10', '', '', '', '', '', '処理名称', '', 'ログ1', 'ログ2', 'ログ3', 'ログ4', 'ログ5');

-- ----------------------------
-- Function structure for CMSF_FUNC_PUT_LOG
-- ----------------------------
DROP FUNCTION IF EXISTS `CMSF_FUNC_PUT_LOG`;
delimiter ;;
CREATE FUNCTION `CMSF_FUNC_PUT_LOG`(p_created_by varchar(255) , p_log_prj_name varchar(255) , p_log_apps_name varchar(255) , p_log_mod_name varchar(255) , p_log_mod_var varchar(255) , p_log_type varchar(255), p_log_title varchar(500) ,p_log_query mediumtext , p_log_text1 varchar(255) , p_log_text2 varchar(255) , p_log_text3 varchar(255) , p_log_text4 varchar(255) , p_log_text5 varchar(255))
 RETURNS varchar(255) CHARSET utf8mb4
  READS SQL DATA 
  DETERMINISTIC
  SQL SECURITY INVOKER
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
 * @param       mediumtext   p_log_query     クエリ
 * @param       varchar(255) p_log_text1     ログ1
 * @param       varchar(255) p_log_text2     ログ2
 * @param       varchar(255) p_log_text3     ログ3
 * @param       varchar(255) p_log_text4     ログ4
 * @param       varchar(255) p_log_text5     ログ5
 * @return      text                         ログ出力処理結果
 * @example
 * @license     MIT ライセンス - https://opensource.org/licenses/mit-license.php
 * @copyright   2009 Yuusuke takagi <takagi.yuusuke@automation.jp>
 * @link        https://github.com/Yuutakasan/COMMON-MYSQL-STORED-FUNCTION
 * @author      Yuusuke takagi <takagi.yuusuke@automation.jp>
 * @version     $Revision: 0.0.1 2009/07/13 初期リリース Yuusuke takagi <takagi.yuusuke@automation.jp$
 * @version     $Revision: 1.0.0 2021/01/06 正式リリース Yuusuke takagi <takagi.yuusuke@automation.jp$
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
 declare w_log_query                    text   default '';                      /* Query Log */
 declare w_sqlstate                     varchar(5)    default '';
 declare w_errno                        varchar(6)    default '';
 declare w_err_text                     varchar(255)   default '';
 declare w_log                          text              default NULL;         /* SQL実行ログ */
 declare w_log_exec_function            text   default '';                      /* 関数実行 */
 
 declare w_start_time                   DATETIME(6)     default NULL;           /* 実行開始時間 */
 declare w_end_time                     DATETIME(6)     default NULL;           /* 実行終了時間 */

 declare w_done                         int(1)          default false;                   /* カーソル実行ログ */
 declare w_rowcount                     int(20)         default  NULL;                   /* カーソル実行ログ */

 /* ユーザー定義変数 */
 declare w_log_prj_name                 varchar(255)    default '';             /*  プロジェクト名 */
 declare w_log_apps_name                varchar(255)    default '';             /*  アプリケーション名 */
 declare w_log_mod_name                 varchar(255)    default '';             /*  モジュール名 */
 declare w_log_mod_var                  varchar(255)    default '';             /*  モジュールバージョン */
 declare w_log_type                     varchar(255)    default '';             /*  Log Type */
 declare w_log_title                    varchar(500)    default '';             /*  Log Title */
 declare w_log_text1                    varchar(255)    default '';             /*  Text Log1 */
 declare w_log_text2                    varchar(255)    default '';             /*  Text Log2 */
 declare w_log_text3                    varchar(255)    default '';             /*  Text Log3 */
 declare w_log_text4                    varchar(255)    default '';             /*  Text Log4 */
 declare w_log_text5                    varchar(255)    default '';             /*  Text Log5 */

 declare w_created_by                   varchar(255)    default '';             /*  データ作成者 */

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
 'SQL'
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
 declare s_log_mod_var                  varchar(255)    default '1.0.0';                        /*  モジュールバージョン */

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

 /*------------------------------------------------------
    ユーザ例外定義
  -------------------------------------------------------*/
 /*------------------------------------------------------
    例外定義
 -------------------------------------------------------*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 w_sqlstate = RETURNED_SQLSTATE, w_errno = MYSQL_ERRNO, w_err_text = MESSAGE_TEXT;
    /* SQLエラーハンドリング */

		SET w_log = CONCAT_WS("",
		                      "ERROR " , w_errno , IF( w_sqlstate IS NULL, " : " , CONCAT_WS("",  "( " , w_sqlstate , ") : " ) )  , w_err_text );

		/*  ログ出力処理  */
		SET w_end_time = SYSDATE();
		SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_error
                                    ,  CONVERT( CONCAT( 'Z.Z.Z エラー処理 :' , s_log_apps_name, '.' , s_log_mod_name , 'にてERRORが発生しました。'  ) USING utf8mb4 ) , w_log_exec_function , w_log , CONCAT( "実行時間:" , TIMESTAMPDIFF( SECOND ,  w_start_time , w_end_time ) , "秒" ) , s_empty_string , s_empty_string , s_empty_string );

     RETURN NULL;
END;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET w_done = TRUE;

DECLARE EXIT HANDLER FOR SQLWARNING
  BEGIN
    GET DIAGNOSTICS CONDITION 1 w_sqlstate = RETURNED_SQLSTATE, w_errno = MYSQL_ERRNO, w_err_text = MESSAGE_TEXT;
    /* SQLエラーハンドリング */
		
		SET w_log = CONCAT_WS("",
		                      "WARNING " , w_errno , IF( w_sqlstate IS NULL, " : " , CONCAT_WS("",  "( " , w_sqlstate , ") : " ) )  , w_err_text );

		/*  ログ出力処理  */
		SET w_end_time = SYSDATE();
		SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_error
                                    ,  CONVERT( CONCAT( 'Z.Z.Z エラー処理 :' , s_log_apps_name, '.' , s_log_mod_name , 'にてWARNINGが発生しました。'  ) USING utf8mb4 ) , w_log_exec_function , w_log , CONCAT( "実行時間:" , TIMESTAMPDIFF( SECOND ,  w_start_time , w_end_time ) , "秒" ) , s_empty_string , s_empty_string , s_empty_string );

     RETURN NULL;
END;

 /*----------------------------------------------------------
   処理定義
 -----------------------------------------------------------*/
 /* 1.0 初期処理*/
SET w_log_exec_function = CONCAT_WS('',"SELECT CMSF_FUNC_PUT_LOG('" , p_created_by , "','" , p_log_prj_name , "','" , p_log_apps_name , "','" , p_log_mod_name , "','" , p_log_mod_var , "','" , p_log_type , "','" , p_log_title , "','" , p_log_query , "','" , p_log_text1 , "','" , p_log_text2  , "','" ,  p_log_text3 , "','" ,  p_log_text4 , "','" , p_log_text5  , "' );" );
 
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
IF( s_log_flg IN( 1 , 2 ) ) THEN
			SET w_start_time = CURRENT_TIMESTAMP(6);
			SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
																						, CONCAT( '1.0 初期処理 ' ) , w_log_exec_function , CONCAT( '開始時間:' , w_start_time ) , s_empty_string , s_empty_string , s_empty_string , s_empty_string );
END IF;

/* 2.1.1 ログ追加処理 */

SET w_rowcount = NULL;

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

SET w_rowcount = ROW_COUNT();

 /*  ログ出力*/
IF( s_log_flg = 1 ) THEN

	SET w_log_query = CONCAT_WS('',
	"INSERT INTO tr_logs(
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
		'" , w_created_by , "',
		SYSDATE(),
		'" , w_log_prj_name , "',
		'" , w_log_apps_name , "',
		'" , w_log_mod_name , "',
		'" , w_log_mod_var , "',
		'" , w_log_type , "',
		'" , w_log_title , "',
		'" , w_log_query , "',
		'" , w_log_text1 , "',
		'" , w_log_text2 , "',
		'" , w_log_text3 , "',
		'" , w_log_text4 , "',
		'" , w_log_text5 , "'
	);"
	 );
			
	SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_insert
																		 , CONCAT_NULLABLE('2.1.1 ログ追加処理' ), w_log_query , CONCAT( w_rowcount ,'件処理しました。') , s_empty_string , s_empty_string , s_empty_string , s_empty_string );

END IF;

SET w_result = s_ok;

/*  ログ出力処理  */
IF( s_log_flg IN( 1 , 2 ) ) THEN
			SET w_end_time   = CURRENT_TIMESTAMP(6);
			SET w_log_result = CMSF_FUNC_PUT_LOG( s_log_created_by , s_log_prj_name , s_log_apps_name , s_log_mod_name , s_log_prg_var , s_log_type_text
																						, CONCAT( '9.9.9 処理完了 :' , w_result  ) , s_empty_string , CONCAT( '開始時間:' , w_start_time ) , CONCAT( '終了時間:' , w_end_time ) , CONCAT( '実行時間:' , TIMESTAMPDIFF(MICROSECOND,w_end_time,w_start_time) , '秒') , s_empty_string , s_empty_string );
END IF;


return w_result;

END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
