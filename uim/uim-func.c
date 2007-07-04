/*

  Copyright (c) 2003-2007 uim Project http://code.google.com/p/uim/

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
  3. Neither the name of authors nor the names of its contributors
     may be used to endorse or promote products derived from this software
     without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGE.

*/

#include <config.h>

#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

#include "uim-internal.h"
#include "uim-scm.h"
#include "uim-scm-abbrev.h"
#include "uim-im-switcher.h"


#define TEXT_EMPTYP(txt) (!(txt) || !(txt)[0])


/* this is not a uim API, so did not name as uim_retrieve_context() */
static uim_context
retrieve_uim_context(uim_lisp c)
{
  uim_context uc;

  if (CONSP(c))  /* passed as Scheme-side input context */
    c = CAR(c);

  uc = uim_scm_c_ptr(c);
  assert(uc);

  return uc;
}

/* extract Scheme IM context from Scheme-object-wrapped uim_context */
static uim_lisp
im_retrieve_context(uim_lisp uc_)
{
  uim_context uc;

  uc = uim_scm_c_ptr(uc_);
  assert(uc);

  return uc->sc;
}

static uim_lisp
im_convertiblep(uim_lisp id, uim_lisp im_encoding_)
{
  uim_context uc;
  const char *im_encoding;

  uc = retrieve_uim_context(id);
  im_encoding = uim_scm_refer_c_str(im_encoding_);
  return MAKE_BOOL(uc->conv_if->is_convertible(uc->client_encoding,
                                               im_encoding));
}

static uim_lisp
im_clear_preedit(uim_lisp uc_)
{
  uim_context uc;

  uc = retrieve_uim_context(uc_);
  if (uc->preedit_clear_cb)
    uc->preedit_clear_cb(uc->ptr);

  return uim_scm_f();
}

static uim_lisp
im_pushback_preedit(uim_lisp uc_, uim_lisp attr_, uim_lisp str_)
{
  uim_context uc;
  const char *str;
  char *converted_str;
  int attr;

  uc = retrieve_uim_context(uc_);
  attr = uim_scm_c_int(attr_);
  str = uim_scm_refer_c_str(str_);

  converted_str = uc->conv_if->convert(uc->outbound_conv, str);
  if (uc->preedit_pushback_cb)
      uc->preedit_pushback_cb(uc->ptr, attr, converted_str);
  free(converted_str);

  return uim_scm_f();
}

static uim_lisp
im_update_preedit(uim_lisp uc_)
{
  uim_context uc;

  uc = retrieve_uim_context(uc_);
  if (uc->preedit_update_cb)
    uc->preedit_update_cb(uc->ptr);

  return uim_scm_f();
}

static uim_lisp
im_commit(uim_lisp uc_, uim_lisp str_)
{
  uim_context uc;
  const char *str;
  char *converted_str;

  uc = retrieve_uim_context(uc_);
  str = uim_scm_refer_c_str(str_);

  converted_str = uc->conv_if->convert(uc->outbound_conv, str);
  if (uc->commit_cb)
    uc->commit_cb(uc->ptr, converted_str);
  free(converted_str);

  return uim_scm_f();
}

static uim_lisp
im_get_raw_key_str(uim_lisp key_, uim_lisp key_state_)
{
  int key;
  int key_state = uim_scm_c_int(key_state_);
  char buf[2];
  
  if (uim_scm_integerp(key_)) {
    key = uim_scm_c_int(key_);
  } else {
    return uim_scm_f();
  }
  if ((key_state != 0 && key_state != UMod_Shift) ||
      key > 255) {
    return uim_scm_f();
  }
  
  buf[0] = key;
  buf[1] = 0;
  if (key_state == UMod_Shift) {
    buf[0] = toupper(buf[0]);
  }
  return uim_scm_make_str(buf);
}

static uim_lisp
im_set_encoding(uim_lisp uc_, uim_lisp enc_)
{
  uim_context uc;
  const char *enc;

  uc = retrieve_uim_context(uc_);
  enc = uim_scm_refer_c_str(enc_);

  if (uc->outbound_conv)
    uc->conv_if->release(uc->outbound_conv);
  if (uc->inbound_conv)
    uc->conv_if->release(uc->inbound_conv);

  if (!strcmp(uc->client_encoding, enc)) {
    uc->outbound_conv = NULL;
    uc->inbound_conv  = NULL;
  } else {
    uc->outbound_conv = uc->conv_if->create(uc->client_encoding, enc);
    uc->inbound_conv  = uc->conv_if->create(enc, uc->client_encoding);
  }

  return uim_scm_f();
}

static uim_lisp
im_clear_mode_list(uim_lisp uc_)
{
  uim_context uc;
  int i;

  uc = retrieve_uim_context(uc_);

  for (i = 0; i < uc->nr_modes; i++) {
    if (uc->modes[i]) {
      free(uc->modes[i]);
      uc->modes[i] = NULL;
    }
  }
  if (uc->modes) {
    free(uc->modes);
    uc->modes = NULL;
  }
  uc->nr_modes = 0;

  return uim_scm_f();
}

static uim_lisp
im_pushback_mode_list(uim_lisp uc_, uim_lisp str_)
{
  uim_context uc;
  const char *str;

  uc = retrieve_uim_context(uc_);
  str = uim_scm_refer_c_str(str_);

  uc->modes = realloc(uc->modes, sizeof(char *) * (uc->nr_modes + 1));
  uc->modes[uc->nr_modes] = uc->conv_if->convert(uc->outbound_conv, str);
  uc->nr_modes++;

  return uim_scm_f();
}

static uim_lisp
im_update_mode_list(uim_lisp uc_)
{
  uim_context uc;

  uc = retrieve_uim_context(uc_);

  if (uc->mode_list_update_cb)
    uc->mode_list_update_cb(uc->ptr);

  return uim_scm_f();
}

static uim_lisp
im_update_prop_list(uim_lisp uc_, uim_lisp prop_)
{
  uim_context uc;
  const char *prop;

  uc = retrieve_uim_context(uc_);
  prop = uim_scm_refer_c_str(prop_);
  
  if (uc->propstr)
    free(uc->propstr);
  uc->propstr = uc->conv_if->convert(uc->outbound_conv, prop);

  if (uc->prop_list_update_cb)
    uc->prop_list_update_cb(uc->ptr, uc->propstr);

  return uim_scm_f();
}

static uim_lisp
im_update_mode(uim_lisp uc_, uim_lisp mode_)
{
  uim_context uc;
  int mode;

  uc = retrieve_uim_context(uc_);
  mode = uim_scm_c_int(mode_);

  uc->mode = mode;
  if (uc->mode_update_cb)
    uc->mode_update_cb(uc->ptr, mode);

  return uim_scm_f();
}

static uim_lisp
im_activate_candidate_selector(uim_lisp uc_,
                               uim_lisp nr_, uim_lisp display_limit_)
{
  uim_context uc;
  int nr, display_limit;

  uc = retrieve_uim_context(uc_);
  nr = uim_scm_c_int(nr_);
  display_limit = uim_scm_c_int(display_limit_);

  if (uc->candidate_selector_activate_cb)
    uc->candidate_selector_activate_cb(uc->ptr, nr, display_limit);

  return uim_scm_f();
}

static uim_lisp
im_select_candidate(uim_lisp uc_, uim_lisp idx_)
{
  uim_context uc;
  int idx;

  uc = retrieve_uim_context(uc_);
  idx = uim_scm_c_int(idx_);

  if (uc->candidate_selector_select_cb)
    uc->candidate_selector_select_cb(uc->ptr, idx);

  return uim_scm_f();
}


/* My naming sense seems bad... */
static uim_lisp
im_shift_page_candidate(uim_lisp uc_, uim_lisp dir_)
{
  uim_context uc;
  int dir;

  uc = retrieve_uim_context(uc_);
  dir = (uim_scm_c_bool(dir_)) ? 1 : 0;
    
  if (uc->candidate_selector_shift_page_cb)
    uc->candidate_selector_shift_page_cb(uc->ptr, dir);

  return uim_scm_f();
}

static uim_lisp
im_deactivate_candidate_selector(uim_lisp uc_)
{
  uim_context uc;

  uc = retrieve_uim_context(uc_);

  if (uc->candidate_selector_deactivate_cb)
    uc->candidate_selector_deactivate_cb(uc->ptr);

  return uim_scm_f();
}

static uim_lisp
im_acquire_text(uim_lisp uc_, uim_lisp text_id_, uim_lisp origin_,
		uim_lisp former_len_, uim_lisp latter_len_)
{
  uim_context uc;
  int err, former_len, latter_len;
  enum UTextArea text_id;
  enum UTextOrigin origin;
  char *former, *latter, *cv_former, *cv_latter;
  uim_lisp former_, latter_, ret;

  uc = retrieve_uim_context(uc_);

  if (!uc->acquire_text_cb)
    return uim_scm_f();

  text_id = uim_scm_c_int(text_id_);
  origin = uim_scm_c_int(origin_);
  former_len = uim_scm_c_int(former_len_);
  latter_len = uim_scm_c_int(latter_len_);

  err = uc->acquire_text_cb(uc->ptr, text_id, origin,
                            former_len, latter_len, &former, &latter);
  if (err)
    return uim_scm_f();

  /* FIXME: string->list is not applied here for each text part. This
   * interface should be revised when SigScheme has been introduced to
   * uim. Until then, perform character separation by each input methods if
   * needed.  -- YamaKen 2006-10-07 */
  cv_former = uc->conv_if->convert(uc->inbound_conv, former);
  cv_latter = uc->conv_if->convert(uc->inbound_conv, latter);
  former_ = (TEXT_EMPTYP(cv_former)) ? uim_scm_null() : MAKE_STR(cv_former);
  latter_ = (TEXT_EMPTYP(cv_latter)) ? uim_scm_null() : MAKE_STR(cv_latter);

  ret = uim_scm_callf("ustr-new", "oo", former_, latter_);

  free(former);
  free(latter);
  free(cv_former);
  free(cv_latter);

  return ret;
}

static uim_lisp
im_delete_text(uim_lisp uc_, uim_lisp text_id_, uim_lisp origin_,
	       uim_lisp former_len_, uim_lisp latter_len_)
{
  uim_context uc;
  int err, former_len, latter_len;
  enum UTextArea text_id;
  enum UTextOrigin origin;

  uc = retrieve_uim_context(uc_);

  if (!uc->delete_text_cb)
    return uim_scm_f();

  text_id = uim_scm_c_int(text_id_);
  origin = uim_scm_c_int(origin_);
  former_len = uim_scm_c_int(former_len_);
  latter_len = uim_scm_c_int(latter_len_);

  err = uc->delete_text_cb(uc->ptr, text_id, origin, former_len, latter_len);

  return uim_scm_make_bool(!err);
}

static uim_lisp
raise_configuration_change(uim_lisp uc_)
{
  uim_context uc;

  uc = retrieve_uim_context(uc_);

  if (uc->configuration_changed_cb)
    uc->configuration_changed_cb(uc->ptr);

  return uim_scm_t();
}

static uim_lisp
switch_app_global_im(uim_lisp uc_, uim_lisp name_)
{
  uim_context uc;
  const char *name;

  uc = retrieve_uim_context(uc_);
  name = uim_scm_refer_c_str(name_);

  if (uc->switch_app_global_im_cb)
    uc->switch_app_global_im_cb(uc->ptr, name);

  return uim_scm_t();
}

static uim_lisp
switch_system_global_im(uim_lisp uc_, uim_lisp name_)
{
  uim_context uc;
  const char *name;

  uc = retrieve_uim_context(uc_);
  name = uim_scm_refer_c_str(name_);

  if (uc->switch_system_global_im_cb)
    uc->switch_system_global_im_cb(uc->ptr, name);

  return uim_scm_t();
}

void
uim_init_im_subrs(void)
{
  uim_scm_init_subr_1("im-retrieve-context", im_retrieve_context);
  uim_scm_init_subr_2("im-set-encoding",     im_set_encoding);
  uim_scm_init_subr_2("im-convertible?",     im_convertiblep);
  /**/
  uim_scm_init_subr_2("im-commit",           im_commit);
  /**/
  uim_scm_init_subr_1("im-clear-preedit",    im_clear_preedit);
  uim_scm_init_subr_3("im-pushback-preedit", im_pushback_preedit);
  uim_scm_init_subr_1("im-update-preedit",   im_update_preedit);
  /**/
  uim_scm_init_subr_1("im-clear-mode-list",    im_clear_mode_list);
  uim_scm_init_subr_2("im-pushback-mode-list", im_pushback_mode_list);
  uim_scm_init_subr_1("im-update-mode-list",   im_update_mode_list);
  uim_scm_init_subr_2("im-update-mode",        im_update_mode);
  /**/
  uim_scm_init_subr_2("im-update-prop-list", im_update_prop_list);
  /**/
  uim_scm_init_subr_3("im-activate-candidate-selector", im_activate_candidate_selector);
  uim_scm_init_subr_2("im-select-candidate", im_select_candidate);
  uim_scm_init_subr_2("im-shift-page-candidate", im_shift_page_candidate);
  uim_scm_init_subr_1("im-deactivate-candidate-selector", im_deactivate_candidate_selector);
  /**/
  uim_scm_init_subr_5("im-acquire-text-internal", im_acquire_text);
  uim_scm_init_subr_5("im-delete-text-internal", im_delete_text);
  /**/
  uim_scm_init_subr_1("im-raise-configuration-change", raise_configuration_change);
  uim_scm_init_subr_2("im-switch-app-global-im", switch_app_global_im);
  uim_scm_init_subr_2("im-switch-system-global-im", switch_system_global_im);

  /* should be replaced with generic Scheme code */
  uim_scm_init_subr_2("im-get-raw-key-str", im_get_raw_key_str);
}
