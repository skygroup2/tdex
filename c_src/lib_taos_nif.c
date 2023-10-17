#include <erl_nif.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <taos.h>

static ErlNifResourceType* TAOS_TYPE;
static ErlNifResourceType* TAOS_RES_TYPE;
static ErlNifResourceType* TAOS_ROW_TYPE;
static ErlNifResourceType* TAOS_FIELD_TYPE;

static ERL_NIF_TERM atom_ok;
static ERL_NIF_TERM atom_error_auth;
static ERL_NIF_TERM atom_error;
static ERL_NIF_TERM atom_invalid_resource;

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

  taos_ptr = (taos_t*)enif_alloc_resource(TAOS_TYPE, sizeof(taos_t));
  taos_ptr->taos = taos_connect(ip, user, pass, db, port);
  ERL_NIF_TERM connect = enif_make_resource(env, taos_ptr);
  enif_release_resource(taos_ptr);
  if(taos_ptr->taos == NULL){
    return enif_make_tuple2(env, atom_error, atom_error_auth);
  }
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
  return enif_make_tuple1(env, atom_ok);
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
  char sql[256];

  if(!enif_get_resource(env, argv[0], TAOS_TYPE, (void**) &taos_ptr)){
    return enif_make_tuple2(env, atom_error, atom_invalid_resource);
  };

  if(!enif_get_string(env, argv[1], sql, sizeof(sql), ERL_NIF_LATIN1)){
    return enif_make_badarg(env);
  };

  res_ptr = (taos_res_t*)enif_alloc_resource(TAOS_RES_TYPE, sizeof(taos_res_t));
  res_ptr->taos_res = taos_query(taos_ptr->taos, sql);
  ERL_NIF_TERM res = enif_make_resource(env, res_ptr);
  enif_release_resource(res_ptr);
  return enif_make_tuple2(env, atom_ok, res);
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

  int res = taos_print_row(str, row_ptr->taos_row, field_ptr->taos_field, num_fields);
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

  unsigned char sizeArr[9] = {0};
  memcpy(sizeArr, pg_data + 4, 4);
  int size = 0;
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
}

static ERL_NIF_TERM taos_fetch_fields_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  taos_res_t* res_ptr = NULL;
  taos_field_t* field_ptr = NULL;
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
// extern void query_callback(void *param, TAOS_RES *res, int code);

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
  return enif_make_tuple1(env, atom_ok);
}



static void free_taos_resource(ErlNifEnv* env, void* obj) {

}

static inline int init_taos_resource(ErlNifEnv* env) {
  const char* mod_taos = "TDEX";
  const char* name_taos = "TAOS_TYPE";
  const char* name_res_taos = "TAOS_RES_TYPE";
  const char* name_row_taos = "TAOS_ROW_TYPE";
  const char* name_field_taos = "TAOS_FIELD_TYPE";
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

  TAOS_TYPE = enif_open_resource_type(env, mod_taos, name_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_TYPE == NULL) return -1;

  TAOS_RES_TYPE = enif_open_resource_type(env, mod_taos, name_res_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_RES_TYPE == NULL) return -1;

  TAOS_ROW_TYPE = enif_open_resource_type(env, mod_taos, name_row_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_ROW_TYPE == NULL) return -1;

  TAOS_FIELD_TYPE = enif_open_resource_type(env, mod_taos, name_field_taos, free_taos_resource, (ErlNifResourceFlags)flags, NULL);
  if(TAOS_FIELD_TYPE == NULL) return -1;

  return 0;
}

static int init_nif(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
  if (init_taos_resource(env) == -1) {
    return -1;
  }
  atom_ok = enif_make_atom(env, "ok");
  atom_error = enif_make_atom(env, "error");  
  atom_error_auth = enif_make_atom(env, "error_auth");  
  atom_invalid_resource = enif_make_atom(env, "invalid_resource");
  return 0;
}

static ErlNifFunc nif_funcs[] = {
  {"taos_connect", 5, taos_connect_nif},
  {"taos_close", 1, taos_close_nif},
  {"taos_select_db", 2, taos_select_db_nif},
  {"taos_query", 2, taos_query_nif},
  {"taos_fetch_fields", 1, taos_fetch_fields_nif},
  {"taos_field_count", 1, taos_field_count_nif},
  {"taos_print_row", 3, taos_print_row_nif},
  {"taos_fetch_raw_block", 1, taos_fetch_raw_block_nif},
  {"taos_errstr", 1, taos_errstr_nif},
  {"taos_errno", 1, taos_errno_nif},
  {"taos_fetch_row", 1, taos_fetch_row_nif},
  {"taos_query_a", 4, taos_query_a_nif},
};

ERL_NIF_INIT(Elixir.Tdex.Wrapper, nif_funcs, init_nif, NULL, NULL, NULL)