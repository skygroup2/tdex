#include <erl_nif.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <taos.h>

static ErlNifResourceType* TAOS_TYPE;
static ErlNifResourceType* TAOS_RES_TYPE;
static ErlNifResourceType* TAOS_ROW_TYPE;
static ErlNifResourceType* TAOS_FIELD_TYPE;
static ErlNifResourceType* TAOS_STMT_TYPE;

static ERL_NIF_TERM atom_ok;
static ERL_NIF_TERM atom_error_connect;
static ERL_NIF_TERM atom_error;
static ERL_NIF_TERM atom_invalid_resource;
static ERL_NIF_TERM atom_excute_statement_fail;
static ERL_NIF_TERM atom_less_memory;

static int32_t boolLen;
static int32_t sintLen;
static int32_t intLen;
static int32_t bintLen;
static int32_t floatLen;
static int32_t doubleLen;
static char is_null;

typedef struct {
  TAOS* taos;
} taos_t;

typedef struct {
  TAOS_RES* taos_res;
} taos_res_t;

typedef struct {
  TAOS_ROW taos_row;
} taos_row_t;

typedef struct {
  TAOS_FIELD* taos_field;
} taos_field_t;

typedef struct {
  TAOS_STMT* stmt;
  TAOS_MULTI_BIND* params;
  int param_count;
} taos_stmt_t;

static void free_parm(TAOS_MULTI_BIND* params, int count);
static ERL_NIF_TERM make_string(ErlNifEnv* env, char* str);

static void free_parm(TAOS_MULTI_BIND* params, int count){
  for(int i = 0; i < count; i++){
    TAOS_MULTI_BIND* prm = params + i;
    if(prm->buffer){
      free(prm->buffer);
      free(prm->length);
      prm->buffer = NULL;
      prm->length = NULL;
      prm->is_null = &is_null;
    }
  }
}

static ERL_NIF_TERM make_string(ErlNifEnv* env, char* str) {
  int str_len = strlen(str);
  ErlNifBinary bin;
  enif_alloc_binary(str_len, &bin);
  memcpy(bin.data, str, str_len);
  ERL_NIF_TERM term = enif_make_binary(env, &bin);
  enif_release_binary(&bin);
  return term;
}

static ERL_NIF_TERM taos_stmt_init_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 2) {
    return enif_make_badarg(env);
  }

  taos_t* taos_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_TYPE, (void**) &taos_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  unsigned sql_length;
  enif_get_list_length(env, argv[1], &sql_length);
  char sql[sql_length+1];
  if(!enif_get_string(env, argv[1], sql, sizeof(sql), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };
  uint param_count = 0;
  for(int i = 0; i < sql_length; i++){
    if(sql[i] == '?') param_count++;
  }
  
  TAOS_STMT *stmt = taos_stmt_init(taos_ptr->taos);
  int code = taos_stmt_prepare(stmt, sql, 0);
  if(code){
    taos_stmt_close(stmt);
    return enif_make_tuple2(env, atom_error, enif_make_int(env, code));
  }
  TAOS_MULTI_BIND* params = NULL;
  if(param_count > 0){
    params = (TAOS_MULTI_BIND*)malloc(sizeof(TAOS_MULTI_BIND) * param_count);
    if(params == NULL){
      taos_stmt_close(stmt);
      return enif_make_tuple2(env, atom_error, atom_less_memory);
    }
  } 
  taos_stmt_t* stmt_ptr = (taos_stmt_t*)enif_alloc_resource(TAOS_STMT_TYPE, sizeof(taos_stmt_t));
  stmt_ptr->stmt = stmt;
  stmt_ptr->params = params;
  stmt_ptr->param_count = param_count;
  ERL_NIF_TERM result = enif_make_resource(env, stmt_ptr);
  enif_release_resource(stmt_ptr);
  return enif_make_tuple2(env, atom_ok, result);
}

static ERL_NIF_TERM taos_stmt_bind_param_batch_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(stmt_ptr->params) taos_stmt_bind_param(stmt_ptr->stmt, stmt_ptr->params);
  free_parm(stmt_ptr->params, stmt_ptr->param_count);
  taos_stmt_add_batch(stmt_ptr->stmt);
  return atom_ok;
}

static ERL_NIF_TERM taos_stmt_execute_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  int exc_res = taos_stmt_execute(stmt_ptr->stmt);
  if (exc_res != 0) {
    char* err = taos_stmt_errstr(stmt_ptr->stmt);
    ERL_NIF_TERM err_msg = make_string(env, err);
    return enif_make_tuple3(env, atom_excute_statement_fail, enif_make_int(env, exc_res), err_msg);
  }
  int affected_rows = taos_stmt_affected_rows(stmt_ptr->stmt);
  return enif_make_tuple2(env, atom_ok, enif_make_int(env, affected_rows));
}

static ERL_NIF_TERM taos_stmt_close_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  taos_stmt_close(stmt_ptr->stmt);
  if(stmt_ptr->params){
    free_parm(stmt_ptr->params, stmt_ptr->param_count);
    free(stmt_ptr->params);
    stmt_ptr->params = NULL;
  }
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_timestamp_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  ulong *buffer = (ulong*)malloc(bintLen);
  if(!enif_get_ulong(env, argv[2], buffer)){
    free(buffer);
    return enif_make_badarg(env);
  };
  
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = bintLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_TIMESTAMP;
  params->buffer_length = bintLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_int_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  int32_t* buffer = (int32_t*)malloc(intLen);
  if(!enif_get_int(env, argv[2], buffer)){
    free(buffer);
    return enif_make_badarg(env);
  };
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = intLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_INT;
  params->buffer_length = intLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_long_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  int64_t* buffer = (int64_t*)malloc(intLen);
  if(!enif_get_long(env, argv[2], buffer)){
    free(buffer);
    return enif_make_badarg(env);
  };
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = bintLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_BIGINT;
  params->buffer_length = bintLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_short_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  int value;
  if(!enif_get_int(env, argv[2], &value)){
    return enif_make_badarg(env);
  };
  int16_t* buffer = (int16_t*)malloc(sintLen);
  *buffer = (int16_t)value;
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = sintLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_SMALLINT;
  params->buffer_length = sintLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_bool_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  uint value;
  if(!enif_get_uint(env, argv[2], &value)){
    return enif_make_badarg(env);
  };
  int8_t* buffer = (int8_t*)malloc(boolLen);
  *buffer = (int8_t)value;
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = boolLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_BOOL;
  params->buffer_length = boolLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_byte_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  int value;
  if(!enif_get_int(env, argv[2], &value)){
    return enif_make_badarg(env);
  };
  int8_t* buffer = (int8_t*)malloc(boolLen);
  *buffer = (int8_t)value;
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = boolLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_TINYINT;
  params->buffer_length = boolLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_float_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  double value;
  if(!enif_get_double(env, argv[2], &value)){
    return enif_make_badarg(env);
  };
  float* buffer = (float*)malloc(floatLen);
  *buffer = (float)value;
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = floatLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_FLOAT;
  params->buffer_length = floatLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_double_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  double* buffer = (double*)malloc(doubleLen);
  if(!enif_get_double(env, argv[2], buffer)){
    free(buffer);
    return enif_make_badarg(env);
  };
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = doubleLen;
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_DOUBLE;
  params->buffer_length = doubleLen;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_varbinary_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  ErlNifBinary bin;
  if(!enif_inspect_binary(env, argv[2], &bin)){
    return enif_make_badarg(env);
  };
  char* buffer = (char*)malloc(bin.size);
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = bin.size;
  memcpy(buffer, bin.data, *len_ptr);
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_VARBINARY;
  params->buffer_length = bin.size;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}

static ERL_NIF_TERM taos_multi_bind_set_varchar_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }
  taos_stmt_t* stmt_ptr = NULL;
  uint index;
  if(!enif_get_resource(env, argv[0], TAOS_STMT_TYPE, (void**) &stmt_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };
  if(!enif_get_uint(env, argv[1], &index)){
    return enif_make_badarg(env);
  };
  ErlNifBinary bin;
  if(!enif_inspect_binary(env, argv[2], &bin)){
    return enif_make_badarg(env);
  };
  char* buffer = (char*)malloc(bin.size);
  int32_t* len_ptr = (int32_t*)malloc(sizeof(int32_t));
  *len_ptr = bin.size;
  memcpy(buffer, bin.data, *len_ptr);
  TAOS_MULTI_BIND* params = stmt_ptr->params + index;
  params->buffer_type = TSDB_DATA_TYPE_VARCHAR;
  params->buffer_length = bin.size;
  params->buffer = buffer;
  params->length = len_ptr;
  params->is_null = 0;
  params->num = 1;
  return atom_ok;
}
/* BASIC API TAOS */
static ERL_NIF_TERM taos_connect_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 5) {
    return enif_make_badarg(env);
  }

  taos_t* taos_ptr = NULL;
  char ip[256], user[256], pass[256], db[256];
  uint port;

  if(!enif_get_string(env, argv[0], ip, sizeof(ip), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  if(!enif_get_string(env, argv[1], user, sizeof(user), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  if(!enif_get_string(env, argv[2], pass, sizeof(pass), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  if(!enif_get_string(env, argv[3], db, sizeof(db), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  if(!enif_get_uint(env, argv[4], &port)){
    return enif_make_badarg(env);
  };

  TAOS *taos = taos_connect(ip, user, pass, db, port);
  if(taos == NULL){
    return enif_make_tuple2(env, atom_error, atom_error_connect);
  }
  taos_options(TSDB_OPTION_TIMEZONE, "UTC");
  taos_ptr = (taos_t*)enif_alloc_resource(TAOS_TYPE, sizeof(taos_t));
  taos_ptr->taos = taos;
  ERL_NIF_TERM connect = enif_make_resource(env, taos_ptr);
  enif_release_resource(taos_ptr);
  return enif_make_tuple2(env, atom_ok, connect);
}

static ERL_NIF_TERM taos_close_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if(argc != 1) {
    return enif_make_badarg(env);
  }

  taos_t* taos_ptr = NULL;

  if(!enif_get_resource(env, argv[0], TAOS_TYPE, (void**) &taos_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  taos_close(taos_ptr->taos);
  return atom_ok;
}

static ERL_NIF_TERM taos_select_db_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 2) {
    return enif_make_badarg(env);
  }

  taos_t* taos_ptr = NULL;
  char db[256];

  if(!enif_get_resource(env, argv[0], TAOS_TYPE, (void**) &taos_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  if(!enif_get_string(env, argv[1], db, sizeof(db), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  int res = taos_select_db(taos_ptr->taos, db);
  return enif_make_tuple2(env, atom_ok, enif_make_int(env, res));
}

/* Synchronous APIs */
static ERL_NIF_TERM taos_query_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 2) {
    return enif_make_badarg(env);
  }

  taos_t* taos_ptr = NULL;
  taos_res_t* res_ptr = NULL;
  

  if(!enif_get_resource(env, argv[0], TAOS_TYPE, (void**) &taos_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  unsigned sql_length;
  enif_get_list_length(env, argv[1], &sql_length);
  char sql[sql_length+1];

  if(!enif_get_string(env, argv[1], sql, sizeof(sql), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  res_ptr = (taos_res_t*)enif_alloc_resource(TAOS_RES_TYPE, sizeof(taos_res_t));
  res_ptr->taos_res = taos_query(taos_ptr->taos, sql);
  ERL_NIF_TERM res = enif_make_resource(env, res_ptr);
  enif_release_resource(res_ptr);
  return enif_make_tuple2(env, atom_ok, res);
}

static ERL_NIF_TERM taos_affected_rows_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  int affected_rows = taos_affected_rows(res_ptr->taos_res);
  return enif_make_tuple2(env, atom_ok, enif_make_int(env, affected_rows));
}

static ERL_NIF_TERM taos_result_precision_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  int precision = taos_result_precision(res_ptr->taos_res);
  return enif_make_tuple2(env, atom_ok, enif_make_int(env, precision));
}

static ERL_NIF_TERM taos_fetch_row_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  taos_row_t* row_ptr = NULL;

  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  row_ptr = (taos_row_t*)enif_alloc_resource(TAOS_ROW_TYPE, sizeof(taos_row_t));
  row_ptr->taos_row = taos_fetch_row(res_ptr->taos_res);
  ERL_NIF_TERM row = enif_make_resource(env, row_ptr);
  enif_release_resource(row_ptr);
  return enif_make_tuple2(env, atom_ok, row);
}

static ERL_NIF_TERM taos_print_row_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_badarg(env);
  }

  char str[1024];
  taos_row_t* row_ptr = NULL;
  taos_field_t* field_ptr = NULL;
  int num_fields;

  if(!enif_get_resource(env, argv[0], TAOS_ROW_TYPE, (void**) &row_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  if(!enif_get_resource(env, argv[1], TAOS_FIELD_TYPE, (void**) &field_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  if(!enif_get_int(env, argv[2], &num_fields)){
    return enif_make_badarg(env);
  };

  taos_print_row(str, row_ptr->taos_row, field_ptr->taos_field, num_fields);
  return enif_make_tuple2(env, atom_ok, enif_make_string(env, str, ERL_NIF_LATIN1));
}

static ERL_NIF_TERM taos_field_count_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  int field_count = taos_field_count(res_ptr->taos_res);
  return enif_make_tuple2(env, atom_ok, enif_make_int(env, field_count));
}

static ERL_NIF_TERM taos_fetch_raw_block_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  int num_of_rows = 0;
  void* pg_data;
  ErlNifBinary bin;

  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  int code = taos_fetch_raw_block(res_ptr->taos_res, &num_of_rows, &pg_data);
  if(code == 0){
    unsigned char sizeArr[9] = {0};
    int size = 0;
    memcpy(sizeArr, pg_data + 4, 4);
    memcpy(&size, sizeArr, 4);
    enif_alloc_binary(size, &bin);
    memcpy(bin.data, pg_data, size);

    ERL_NIF_TERM block_bin = enif_make_binary(env, &bin);
    enif_release_binary(&bin);
    return enif_make_tuple3(
      env, 
      atom_ok, 
      enif_make_int(env, num_of_rows),
      block_bin
    );
  } else {
    const char* err_str = taos_errstr(res_ptr->taos_res);
    return enif_make_tuple2(
      env, 
      atom_error, 
      enif_make_string(env, err_str, ERL_NIF_LATIN1)
    );
  }
}

static ERL_NIF_TERM taos_free_result_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  taos_free_result(res_ptr->taos_res);
  return atom_ok;
}

static ERL_NIF_TERM taos_cleanup_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 0) {
    return enif_make_badarg(env);
  }

  taos_cleanup();
  return atom_ok;
}


static ERL_NIF_TERM taos_fetch_fields_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  ErlNifBinary bin;

  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  int field_count = taos_field_count(res_ptr->taos_res);
  int size = field_count * 72;
  TAOS_FIELD* fields = taos_fetch_fields(res_ptr->taos_res);
  enif_alloc_binary(size, &bin);
  memcpy(bin.data, fields, size);
  
  ERL_NIF_TERM fields_bin = enif_make_binary(env, &bin);
  enif_release_binary(&bin);
  return enif_make_tuple2(env, atom_ok, fields_bin);
}

static ERL_NIF_TERM taos_errstr_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  const char* err_str = taos_errstr(res_ptr->taos_res);
  return enif_make_tuple2(env, atom_ok, enif_make_string(env, err_str, ERL_NIF_LATIN1));
}

static ERL_NIF_TERM taos_errno_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  if(!enif_get_resource(env, argv[0], TAOS_RES_TYPE, (void**) &res_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  int err_no = taos_errno(res_ptr->taos_res);
  if(err_no == 0) return enif_make_tuple2(env, atom_ok, enif_make_int(env, err_no));
  return enif_make_tuple2(env, atom_error, enif_make_int(env, err_no));
}

/* Asynchronous APIs */

static ERL_NIF_TERM taos_query_a_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 4) {
    return enif_make_badarg(env);
  }

  taos_t* taos_ptr = NULL;
  char sql[256];
  if(!enif_get_resource(env, argv[0], TAOS_TYPE, (void**) &taos_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  if(!enif_get_string(env, argv[1], sql, sizeof(sql), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  taos_query_a(taos_ptr->taos, sql, NULL, NULL);
  return atom_ok;
}



static void free_taos_resource(ErlNifEnv* env, void* obj) {

}

static inline int init_taos_resource(ErlNifEnv* env) {
  const char* mod_taos = "TDEX";
  const char* name_taos = "TAOS_TYPE";
  const char* name_res_taos = "TAOS_RES_TYPE";
  const char* name_row_taos = "TAOS_ROW_TYPE";
  const char* name_field_taos = "TAOS_FIELD_TYPE";
  const char* name_stmt_type = "TAOS_STMT_TYPE";
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

  TAOS_TYPE = enif_open_resource_type(env, mod_taos, name_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_TYPE == NULL) return -1;

  TAOS_RES_TYPE = enif_open_resource_type(env, mod_taos, name_res_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_RES_TYPE == NULL) return -1;

  TAOS_ROW_TYPE = enif_open_resource_type(env, mod_taos, name_row_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_ROW_TYPE == NULL) return -1;

  TAOS_FIELD_TYPE = enif_open_resource_type(env, mod_taos, name_field_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_FIELD_TYPE == NULL) return -1;

  TAOS_STMT_TYPE = enif_open_resource_type(env, mod_taos, name_stmt_type, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_STMT_TYPE == NULL) return -1;

  return 0;
}

static int init_nif(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
  if (init_taos_resource(env) == -1) {
    return -1;
  }
  atom_ok = enif_make_atom(env, "ok");
  atom_error = enif_make_atom(env, "error");  
  atom_error_connect = enif_make_atom(env, "error_connect");  
  atom_invalid_resource = enif_make_atom(env, "invalid_resource");
  atom_excute_statement_fail = enif_make_atom(env, "exc_fail");
  atom_less_memory = enif_make_atom(env, "less_memory");

  boolLen = sizeof(int8_t);
  sintLen = sizeof(int16_t);
  intLen = sizeof(int32_t);
  bintLen = sizeof(int64_t);
  floatLen = sizeof(float);
  doubleLen = sizeof(double);
  is_null = 1;
  return 0;
}

static ErlNifFunc nif_funcs[] = {
  {"taos_connect", 5, taos_connect_nif},
  {"taos_close", 1, taos_close_nif},
  {"taos_select_db", 2, taos_select_db_nif},
  {"taos_query", 2, taos_query_nif},
  {"taos_affected_rows", 1, taos_affected_rows_nif},
  {"taos_result_precision", 1, taos_result_precision_nif},
  {"taos_free_result", 1, taos_free_result_nif},
  {"taos_fetch_fields", 1, taos_fetch_fields_nif},
  {"taos_field_count", 1, taos_field_count_nif},
  {"taos_print_row", 3, taos_print_row_nif},
  {"taos_cleanup", 0, taos_cleanup_nif},
  {"taos_fetch_raw_block", 1, taos_fetch_raw_block_nif},
  {"taos_errstr", 1, taos_errstr_nif},
  {"taos_errno", 1, taos_errno_nif},
  {"taos_fetch_row", 1, taos_fetch_row_nif},
  {"taos_query_a", 4, taos_query_a_nif},
  {"taos_stmt_init", 2, taos_stmt_init_nif},
  {"taos_stmt_bind_param_batch", 1, taos_stmt_bind_param_batch_nif},
  {"taos_stmt_execute", 1, taos_stmt_execute_nif},
  {"taos_stmt_close", 1, taos_stmt_close_nif},
  {"taos_multi_bind_set_timestamp", 3, taos_multi_bind_set_timestamp_nif},
  {"taos_multi_bind_set_byte", 3, taos_multi_bind_set_byte_nif},
  {"taos_multi_bind_set_int", 3, taos_multi_bind_set_int_nif},
  {"taos_multi_bind_set_long", 3, taos_multi_bind_set_long_nif},
  {"taos_multi_bind_set_short", 3, taos_multi_bind_set_short_nif},
  {"taos_multi_bind_set_bool", 3, taos_multi_bind_set_bool_nif},
  {"taos_multi_bind_set_float", 3, taos_multi_bind_set_float_nif},
  {"taos_multi_bind_set_double", 3, taos_multi_bind_set_double_nif},
  {"taos_multi_bind_set_varbinary", 3, taos_multi_bind_set_varbinary_nif},
  {"taos_multi_bind_set_varchar", 3, taos_multi_bind_set_varchar_nif}
};

// static void log(format, ){
//   FILE * pFile;
//   pFile = fopen ("enif.log","wa");
//   enif_fprintf(pFile, format);
//   fclose(pFile);
// }
ERL_NIF_INIT(Elixir.Tdex.Wrapper, nif_funcs, init_nif, NULL, NULL, NULL)