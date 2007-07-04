;;;
;;; Copyright (c) 2003-2007 uim Project http://code.google.com/p/uim/
;;;
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:
;;; 1. Redistributions of source code must retain the above copyright
;;;    notice, this list of conditions and the following disclaimer.
;;; 2. Redistributions in binary form must reproduce the above copyright
;;;    notice, this list of conditions and the following disclaimer in the
;;;    documentation and/or other materials provided with the distribution.
;;; 3. Neither the name of authors nor the names of its contributors
;;;    may be used to endorse or promote products derived from this software
;;;    without specific prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND
;;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
;;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.
;;;;

;;; tutcode.scm: TUT-Code for Japanese input.
;;;
;;; TUT-Code<http://www.crew.sfc.keio.ac.jp/~chk/>入力スクリプト。
;;; TUT-Code配列で日本語の入力を行う。
;;;
;;; デフォルトのコード表(キーストロークと入力される文字との対応)
;;; であるtutcode-ruleはQWERTYキーボード用。
;;;
;;; 【部首合成変換】
;;;   前置型のみ実装しています。
;;;   再帰的な部首合成変換も可能です。
;;;   部首合成のアルゴリズムはtc-2.1のものです。
;;; 
;;; 【交ぜ書き変換】
;;;   単純な前置型交ぜ書き変換ができます。
;;;   交ぜ書き変換辞書はtc2と同じ形式(SKK辞書と同様の形式)です。
;;; 
;;; * 交ぜ書き変換辞書(例:/usr/local/share/tc/mazegaki.dic)へのアクセスは
;;;   libuim-skk.soの機能を使っています。
;;;   そのため、学習機能もSKKと同様の動作になります:
;;;     確定した候補は次回の変換から先頭に来ます。
;;;     確定した候補は個人辞書(~/.mazegaki.dic)に保存されます。
;;; 
;;; * 活用する語の変換は自動的には行いません。
;;;   読みに明示的に"―"を付加して変換してください。
;;; 
;;; * 交ぜ書き変換関係で未実装の機能
;;;  - 後置型交ぜ書き変換
;;;  - 交ぜ書き変換辞書への登録・削除、
;;;  - 読みを伸ばしたり縮めたりする機能、読みの補完機能
;;;  - 候補選択ウィンドウの使用
;;;
;;; 【設定例】
;;; * コード表の一部を変更したい場合は、例えば~/.uimで以下のように記述する。
;;;   (require "tutcode.scm")
;;;   (tutcode-rule-set-sequences!
;;;     '(((("s" " "))("―"))                ; 記号の定義を変更
;;;       ((("a" "l" "i"))("捗"))            ; 追加
;;;       ((("d" "l" "u"))("づ" "ヅ"))       ; カタカナを含む場合
;;;       ((("d" "l" "d" "u"))("っ" "ッ"))))
;;;
;;; * T-Codeを使いたい場合
;;;   uim-pref-gtk等で設定するか、~/.uimで以下のように設定してください。
;;;    (define tutcode-rule-filename "/usr/local/share/uim/tcode.scm")
;;;    (define tutcode-mazegaki-start-sequence "fj")
;;;    (define tutcode-bushu-start-sequence "jf")
;;;
;;; 【ソースについて】
;;; generic.scmをベースにして以下の変更をしている。
;;;  * キーシーケンス中のスペースが有効になるように変更。
;;;  * ひらがな/カタカナモードの切り替えを追加。
;;;  * rk入力中の未確定(preedit)文字列の表示をしないようにした
;;;    (EmacsのT/TUT-Code入力環境tc2では表示しないのでそれに合わせて)。
;;;  * 交ぜ書き変換ではSKK形式の辞書を使うので、
;;;    skk.scmのかな漢字変換処理から必要な部分を取り込み。
;;;  * 部首合成変換機能を追加。

(require "generic.scm")
(require-custom "tutcode-custom.scm")
(require-custom "generic-key-custom.scm")
(require-custom "tutcode-key-custom.scm")
(load-plugin "skk") ;SKK形式の交ぜ書き辞書の検索のため、libuim-skk.soをロード
(require "tutcode-bushudic.scm") ;部首合成変換辞書

;;; user configs

;; widgets and actions

;; widgets
(define tutcode-widgets '(widget_tutcode_input_mode))

;; default activity for each widgets
(define default-widget_tutcode_input_mode 'action_tutcode_direct)

;; actions of widget_tutcode_input_mode
(define tutcode-input-mode-actions
  '(action_tutcode_direct
    action_tutcode_hiragana
    action_tutcode_katakana))

;;; 使用するコード表。
;;; tutcode-context-new時に(tutcode-custom-load-rule!)で設定
(define tutcode-rule ())

;;; コード表を上書き変更/追加するためのコード表。
;;; ~/.uimでtutcode-rule-set-sequences!で登録して、
;;; tutcode-context-new時に反映する。
(define tutcode-rule-userconfig ())

;;; implementations

;;; 交ぜ書き変換辞書の初期化が終わっているかどうか
(define tutcode-dic-init #f)

(define tutcode-prepare-activation
  (lambda (tc)
    (let ((rkc (tutcode-context-rk-context tc)))
      (rk-flush rkc))))

(register-action 'action_tutcode_direct
		 (lambda (tc)
		   '(ja_halfwidth_alnum
		     "a"
		     "直接入力"
		     "直接入力モード"))
		 (lambda (tc)
		   (not (tutcode-context-on? tc)))
		 (lambda (tc)
		   (tutcode-prepare-activation tc)
		   (tutcode-context-set-state! tc 'tutcode-state-off)))

(register-action 'action_tutcode_hiragana
		 (lambda (tc)
		   '(ja_hiragana
		     "あ"
		     "ひらがな"
		     "ひらがなモード"))
		 (lambda (tc)
		   (and (tutcode-context-on? tc)
			(not (tutcode-context-katakana-mode? tc))))
		 (lambda (tc)
		   (tutcode-prepare-activation tc)
		   (tutcode-context-set-state! tc 'tutcode-state-on)
		   (tutcode-context-set-katakana-mode! tc #f)))

(register-action 'action_tutcode_katakana
		 (lambda (tc)
		   '(ja_katakana
		     "ア"
		     "カタカナ"
		     "カタカナモード"))
		 (lambda (tc)
		   (and (tutcode-context-on? tc)
			(tutcode-context-katakana-mode? tc)))
		 (lambda (tc)
		   (tutcode-prepare-activation tc)
		   (tutcode-context-set-state! tc 'tutcode-state-on)
		   (tutcode-context-set-katakana-mode! tc #t)))

;; Update widget definitions based on action configurations. The
;; procedure is needed for on-the-fly reconfiguration involving the
;; custom API
(define tutcode-configure-widgets
  (lambda ()
    (register-widget 'widget_tutcode_input_mode
		     (activity-indicator-new tutcode-input-mode-actions)
		     (actions-new tutcode-input-mode-actions))))

(define tutcode-context-rec-spec
  (append
   context-rec-spec
   '((rk-context    ()) ; キーストロークから文字への変換のためのコンテキスト
     ;;; TUT-Code入力状態
     ;;; 'tutcode-state-off TUT-Codeオフ
     ;;; 'tutcode-state-on TUT-Codeオン
     ;;; 'tutcode-state-yomi 交ぜ書き変換の読み入力中
     ;;; 'tutcode-state-converting 交ぜ書き変換の候補選択中
     ;;; 'tutcode-state-bushu 部首入力・変換中
     (state 'tutcode-state-off)
     ;;; カタカナモードかどうか
     ;;; #t: カタカナモード。#f: ひらがなモード。
     (katakana-mode #f)
     ;;; 交ぜ書き変換/部首合成変換の対象の文字列リスト(逆順)
     ;;; (例: 交ぜ書き変換で読み「かん字」を入力した場合、("字" "ん" "か"))
     (head ())
     ;;; 交ぜ書き変換の選択中の候補の番号
     (nth 0)
     ;;; 交ぜ書き変換の候補数
     (nr-candidates 0))))
(define-record 'tutcode-context tutcode-context-rec-spec)
(define tutcode-context-new-internal tutcode-context-new)
(define tutcode-context-katakana-mode? tutcode-context-katakana-mode)
(define (tutcode-context-on? pc)
  (not (eq? (tutcode-context-state pc) 'tutcode-state-off)))

;;; TUT-Codeのコンテキストを新しく生成する。
;;; @return 生成したコンテキスト
(define (tutcode-context-new id im)
  (if (not tutcode-dic-init)
    (begin
      (set! tutcode-dic-init #t)
      (skk-lib-dic-open tutcode-dic-filename #f "localhost" 0 'unspecified)
      (tutcode-read-personal-dictionary)))
  (let ((tc (tutcode-context-new-internal id im)))
    (tutcode-context-set-widgets! tc tutcode-widgets)
    (tutcode-custom-load-rule! tutcode-rule-filename)
    (if tutcode-use-dvorak?
      (set! tutcode-rule (tutcode-rule-qwerty-to-dvorak tutcode-rule)))
    ;; tutcode-mazegaki/bushu-start-sequenceは、
    ;; tutcode-use-dvorak?がオンのときはDvorakのシーケンスとみなして反映する。
    ;; つまり、ruleのqwerty-to-dvorak変換後に反映する。
    (tutcode-custom-set-mazegaki/bushu-start-sequence!)
    (tutcode-rule-commit-sequences! tutcode-rule-userconfig)
    (tutcode-context-set-rk-context! tc (rk-context-new tutcode-rule #t #f))
    tc))

;;; ひらがな/カタカナモードの切り替えを行う。
;;; 現状の状態がひらがなモードの場合はカタカナモードに切り替える。
;;; 現状の状態がカタカナモードの場合はひらがなモードに切り替える。
;;; @param pc コンテキストリスト
(define (tutcode-context-kana-toggle pc)
  (let ((s (tutcode-context-katakana-mode? pc)))
    (tutcode-context-set-katakana-mode! pc (not s))))

;;; 交ぜ書き変換用個人辞書を読み込む。
(define (tutcode-read-personal-dictionary)
  (if (not (setugid?))
      (skk-lib-read-personal-dictionary tutcode-personal-dic-filename)))

;;; 交ぜ書き変換用個人辞書を書き込む。
(define (tutcode-save-personal-dictionary)
  (if (not (setugid?))
      (skk-lib-save-personal-dictionary tutcode-personal-dic-filename)))

;;; キーストロークから文字への変換のためのrk-push-key!を呼び出す。
;;; 戻り値が#fでなければ、戻り値(リスト)のcarを返す。
;;; ただし、カタカナモードの場合は戻り値リストのcadrを返す。
;;; (rk-push-key!はストローク途中の場合は#fを返す)
;;; @param pc コンテキストリスト
;;; @param key キーの文字列
(define (tutcode-push-key! pc key)
  (let ((res (rk-push-key! (tutcode-context-rk-context pc) key)))
    (and res
      (if
        (and
          (not (null? (cdr res)))
          (tutcode-context-katakana-mode? pc))
        (cadr res)
        (car res)))))

;;; 変換中状態をクリアする。
;;; @param pc コンテキストリスト
(define (tutcode-flush pc)
  (rk-flush (tutcode-context-rk-context pc))
  (tutcode-context-set-state! pc 'tutcode-state-on)
  (tutcode-context-set-head! pc ())
  (tutcode-context-set-nr-candidates! pc 0))

;;; 変換対象の文字列リストから文字列を作る。
;;; @param sl 文字列リスト
(define (tutcode-make-string sl)
  (if (null? sl)
    ""
    (string-append (tutcode-make-string (cdr sl)) (car sl))))

;;; 交ぜ書き変換中のn番目の候補を返す。
;;; @param pc コンテキストリスト
;;; @param n 対象の候補番号
(define (tutcode-get-nth-candidate pc n)
  (let* ((head (tutcode-context-head pc))
         (cand (skk-lib-get-nth-candidate
                n (tutcode-make-string head) "" "" #f)))
    cand))

;;; 交ぜ書き変換中の現在選択中の候補を返す。
;;; @param pc コンテキストリスト
(define (tutcode-get-current-candidate pc)
  (tutcode-get-nth-candidate pc (tutcode-context-nth pc)))

;;; 交ぜ書き変換で確定した文字列を返す。
;;; @param pc コンテキストリスト
(define (tutcode-prepare-commit-string pc)
  (let* ((res (tutcode-get-current-candidate pc)))
    ;; skk-lib-commit-candidateを呼ぶと学習も行われる
    (skk-lib-commit-candidate
      (tutcode-make-string (tutcode-context-head pc)) "" ""
        (tutcode-context-nth pc) #f)
    (if (> (tutcode-context-nth pc) 0)
      (tutcode-save-personal-dictionary))
    (tutcode-flush pc)
    res))

;;; 交ぜ書き変換の読み/部首合成変換の部首(文字列リストhead)に文字列を追加する。
;;; @param pc コンテキストリスト
;;; @param str 追加する文字列
(define (tutcode-append-string pc str)
  (if (and str (string? str))
    (tutcode-context-set-head! pc
      (cons str
        (tutcode-context-head pc)))))

;;; 交ぜ書き辞書の検索を行う。
;;; @param pc コンテキストリスト
(define (tutcode-begin-conversion pc)
  (let* ((yomi (tutcode-make-string (tutcode-context-head pc)))
         (res (skk-lib-get-entry yomi "" "" #f)))
    (if res
      (begin
        (tutcode-context-set-nth! pc 0)
        (tutcode-context-set-nr-candidates! pc
         (skk-lib-get-nr-candidates yomi "" "" #f))
        (tutcode-context-set-state! pc 'tutcode-state-converting)
        ;; 候補が1個しかない場合は自動的に確定する
        (if (= (tutcode-context-nr-candidates pc) 1)
          (im-commit pc (tutcode-prepare-commit-string pc))))
      ;(tutcode-flush pc) ; flushすると入力した文字列が消えてがっかり
      )))

;;; preedit表示を更新する。
;;; @param pc コンテキストリスト
(define (tutcode-update-preedit pc)
  (let ((rkc (tutcode-context-rk-context pc))
        (stat (tutcode-context-state pc)))
    (im-clear-preedit pc)
    (case stat
      ((tutcode-state-yomi)
        (im-pushback-preedit pc preedit-none "△")
        (let ((h (tutcode-make-string (tutcode-context-head pc))))
          (if (string? h)
            (im-pushback-preedit pc preedit-none h))))
      ((tutcode-state-converting)
        (im-pushback-preedit pc preedit-none "△")
        (im-pushback-preedit pc preedit-none
          (tutcode-get-current-candidate pc)))
      ;; 部首合成変換のマーカ▲は文字列としてhead内で管理(再帰的部首合成のため)
      ((tutcode-state-bushu)
        (let ((h (tutcode-make-string (tutcode-context-head pc))))
          (if (string? h)
            (im-pushback-preedit pc preedit-none h)))))
    (im-pushback-preedit pc preedit-cursor "")
    (im-update-preedit pc)))

;;; TUT-Code入力状態のときのキー入力を処理する。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-proc-state-on pc key key-state)
  (let ((rkc (tutcode-context-rk-context pc)))
    (cond
      ((and
        (tutcode-vi-escape-key? key key-state)
        tutcode-use-with-vi?)
       (rk-flush rkc)
       (tutcode-context-set-state! pc 'tutcode-state-off)
       (im-commit-raw pc)) ; ESCキーをアプリにも渡す
      ((tutcode-off-key? key key-state)
       (rk-flush rkc)
       (tutcode-context-set-state! pc 'tutcode-state-off))
      ((tutcode-kana-toggle-key? key key-state)
       (rk-flush rkc)
       (tutcode-context-kana-toggle pc))
      ((tutcode-backspace-key? key key-state)
       (if (> (length (rk-context-seq rkc)) 0)
         (rk-flush rkc)
         (im-commit-raw pc)))
      ((or
        (symbol? key)
        (and
          (modifier-key-mask key-state)
          (not (shift-key-mask key-state))))
       (rk-flush rkc)
       (im-commit-raw pc))
      ;; 正しくないキーシーケンスは全て捨てる(tc2に合わせた動作)。
      ;; (rk-push-key!すると、途中までのシーケンスは捨てられるが、
      ;; 間違ったキーは残ってしまうので、rk-push-key!は使えない)
      ((not (member (charcode->string key) (rk-expect rkc)))
       (if (> (length (rk-context-seq rkc)) 0)
         (rk-flush rkc) ; 正しくないシーケンスは捨てる
         (im-commit-raw pc))) ; 単独のキー入力(TUT-Code入力でなくて)
      (else
       (let ((res (tutcode-push-key! pc (charcode->string key))))
         (if res
           (case res
            ((tutcode-mazegaki-start)
              (tutcode-context-set-state! pc 'tutcode-state-yomi))
            ((tutcode-bushu-start)
              (tutcode-context-set-state! pc 'tutcode-state-bushu)
              (tutcode-append-string pc "▲"))
            (else
              (im-commit pc res)))))))))

;;; 直接入力状態のときのキー入力を処理する。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-proc-state-off pc key key-state)
  (if
   (tutcode-on-key? key key-state)
   (tutcode-context-set-state! pc 'tutcode-state-on)
   (im-commit-raw pc)))

;;; 交ぜ書き変換の読み入力状態のときのキー入力を処理する。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-proc-state-yomi pc key key-state)
  (let* ((rkc (tutcode-context-rk-context pc))
         (res #f))
    (cond
      ((tutcode-off-key? key key-state)
       (tutcode-flush pc)
       (tutcode-context-set-state! pc 'tutcode-state-off))
      ((tutcode-kana-toggle-key? key key-state)
       (rk-flush rkc)
       (tutcode-context-kana-toggle pc))
      ((tutcode-backspace-key? key key-state)
       (if (> (length (rk-context-seq rkc)) 0)
        (rk-flush rkc)
        (if (> (length (tutcode-context-head pc)) 0)
          (tutcode-context-set-head! pc (cdr (tutcode-context-head pc))))))
      ((or
        (tutcode-commit-key? key key-state)
        (tutcode-return-key? key key-state))
       (im-commit pc (tutcode-make-string (tutcode-context-head pc)))
       (tutcode-flush pc))
      ((tutcode-cancel-key? key key-state)
       (tutcode-flush pc))
      ((symbol? key)
       (tutcode-flush pc)
       (tutcode-proc-state-on pc key key-state))
      ((and
        (modifier-key-mask key-state)
        (not (shift-key-mask key-state)))
       ;; <Control>n等での変換開始?
       (if (tutcode-begin-conv-key? key key-state)
         (if (not (null? (tutcode-context-head pc)))
           (tutcode-begin-conversion pc)
           (tutcode-flush pc))
         (begin
           (tutcode-flush pc)
           (tutcode-proc-state-on pc key key-state))))
      ((not (member (charcode->string key) (rk-expect rkc)))
       (if (> (length (rk-context-seq rkc)) 0)
         (rk-flush rkc)
         ;; spaceキーでの変換開始?
         ;; (spaceはキーシーケンスに含まれる場合があるので、
         ;;  rk-expectにspaceが無いことが条件)
         ;; (trycodeでspaceで始まるキーシーケンスを使っている場合、
         ;;  spaceで変換開始はできないので、<Control>n等を使う必要あり)
         (if (tutcode-begin-conv-key? key key-state)
           (if (not (null? (tutcode-context-head pc)))
             (tutcode-begin-conversion pc)
             (tutcode-flush pc))
           (set! res (charcode->string key)))))
      (else
       (set! res (tutcode-push-key! pc (charcode->string key)))))
    (if res
      (tutcode-append-string pc res))))

;;; 部首合成変換の部首入力状態のときのキー入力を処理する。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-proc-state-bushu pc key key-state)
  (let* ((rkc (tutcode-context-rk-context pc))
         (res #f))
    (cond
      ((tutcode-off-key? key key-state)
       (tutcode-flush pc)
       (tutcode-context-set-state! pc 'tutcode-state-off))
      ((tutcode-kana-toggle-key? key key-state)
       (rk-flush rkc)
       (tutcode-context-kana-toggle pc))
      ((tutcode-backspace-key? key key-state)
       (if (> (length (rk-context-seq rkc)) 0)
        (rk-flush rkc)
        ;; headの1文字目は部首合成変換のマーク▲。backspaceでは消せないように
        ;; する。間違って確定済の文字を消さないようにするため。
        (if (> (length (tutcode-context-head pc)) 1)
          (tutcode-context-set-head! pc (cdr (tutcode-context-head pc))))))
      ((or
        (tutcode-commit-key? key key-state)
        (tutcode-return-key? key key-state))
        ;; 再帰的部首合成変換を(確定して)一段戻す
        (set! res (car (tutcode-context-head pc)))
        (tutcode-context-set-head! pc (cdr (tutcode-context-head pc)))
        (if (not (string=? res "▲"))
          ;; もう1文字(▲のはず)を消して、▲を消す
          (tutcode-context-set-head! pc (cdr (tutcode-context-head pc)))
          (set! res #f))
        (if (= (length (tutcode-context-head pc)) 0)
          (begin
            ;; 最上位の部首合成変換の場合、変換途中の部首があればcommit
            (if res
              (im-commit pc res))
            (tutcode-flush pc)
            (set! res #f))))
      ((tutcode-cancel-key? key key-state)
        ;; 再帰的部首合成変換を(キャンセルして)一段戻す
        (set! res (car (tutcode-context-head pc)))
        (tutcode-context-set-head! pc (cdr (tutcode-context-head pc)))
        (if (not (string=? res "▲"))
          ;; もう1文字(▲のはず)を消して、▲を消す
          (tutcode-context-set-head! pc (cdr (tutcode-context-head pc))))
        (set! res #f)
        (if (= (length (tutcode-context-head pc)) 0)
          (tutcode-flush pc)))
      ((or
        (symbol? key)
        (and
          (modifier-key-mask key-state)
          (not (shift-key-mask key-state))))
       (tutcode-flush pc)
       (tutcode-proc-state-on pc key key-state))
      ((not (member (charcode->string key) (rk-expect rkc)))
       (if (> (length (rk-context-seq rkc)) 0)
         (rk-flush rkc)
         (set! res (charcode->string key))))
      (else
       (set! res (tutcode-push-key! pc (charcode->string key)))
       (case res
        ((tutcode-mazegaki-start) ; 部首合成変換中は交ぜ書き変換は無効にする
          (set! res #f))
        ((tutcode-bushu-start) ; 再帰的な部首合成変換
          (tutcode-append-string pc "▲")
          (set! res #f)))))
    (if res
      (let loop ((prevchar (car (tutcode-context-head pc)))
                  (char res))
        (if (string=? prevchar "▲")
          (tutcode-append-string pc char)
          ;; 直前の文字が部首合成マーカでない→2文字目が入力された→変換開始
          (begin
            (set! char
              (tutcode-bushu-convert prevchar char))
            (if (string? char)
              ;; 合成成功
              (begin
                ;; 1番目の部首と▲を消す
                (tutcode-context-set-head! pc (cddr (tutcode-context-head pc)))
                (if (= (length (tutcode-context-head pc)) 0)
                  ;; 変換待ちの部首が残ってなければ、確定して終了
                  (begin
                    (im-commit pc char)
                    (tutcode-flush pc))
                  ;; 部首がまだ残ってれば、再確認。
                  ;; (合成した文字が2文字目ならば、連続して部首合成変換)
                  (loop
                    (car (tutcode-context-head pc))
                    char)))
              ;; 合成失敗時は入力し直しを待つ
              )))))))

;;; 交ぜ書き変換中の選択候補番号を1増やす。
;;; @param pc コンテキストリスト
(define (tutcode-incr-candidate-index pc)
  (let ((nth (tutcode-context-nth pc)))
    (if (< (+ nth 1) (tutcode-context-nr-candidates pc))
      (tutcode-context-set-nth! pc (+ nth 1)))))

;;; 交ぜ書き変換中の選択候補番号を1減らす。
;;; @param pc コンテキストリスト
(define (tutcode-decr-candidate-index pc)
  (let ((nth (tutcode-context-nth pc)))
    (if (>= (- nth 1) 0)
      (tutcode-context-set-nth! pc (- nth 1)))))

;;; 交ぜ書き変換の候補選択状態から、読み入力状態に戻す。
;;; @param pc コンテキストリスト
(define (tutcode-back-to-yomi-state pc)
  (tutcode-context-set-state! pc 'tutcode-state-yomi)
  (tutcode-context-set-nr-candidates! pc 0))

;;; 交ぜ書き変換の候補選択状態のときのキー入力を処理する。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-proc-state-converting pc key key-state)
  (cond
    ((tutcode-next-candidate-key? key key-state)
      (tutcode-incr-candidate-index pc))
    ((tutcode-prev-candidate-key? key key-state)
      (tutcode-decr-candidate-index pc))
    ((tutcode-cancel-key? key key-state)
      (tutcode-back-to-yomi-state pc))
    ((or
      (tutcode-commit-key? key key-state)
      (tutcode-return-key? key key-state))
      (im-commit pc (tutcode-prepare-commit-string pc)))
    (else
      (im-commit pc (tutcode-prepare-commit-string pc))
      (tutcode-proc-state-on pc key key-state))))

;;; 部首合成変換を行う。
;;; @param c1 1番目の部首
;;; @param c2 2番目の部首
;;; @return 合成後の文字。合成できなかったときは#f
(define (tutcode-bushu-convert c1 c2)
  ;; tc-2.1+[tcode-ml:1925]の部首合成アルゴリズムを使用
  (and c1 c2
    (or
      (tutcode-bushu-compose-sub c1 c2)
      (let ((a1 (tutcode-bushu-alternative c1))
            (a2 (tutcode-bushu-alternative c2)))
        (and
          (or
            (not (string=? a1 c1))
            (not (string=? a2 c2)))
          (begin
            (set! c1 a1)
            (set! c2 a2)
            #t)
          (tutcode-bushu-compose-sub c1 c2)))
      (let* ((decomposed1 (tutcode-bushu-decompose c1))
             (decomposed2 (tutcode-bushu-decompose c2))
             (tc11 (and decomposed1 (car decomposed1)))
             (tc12 (and decomposed1 (cadr decomposed1)))
             (tc21 (and decomposed2 (car decomposed2)))
             (tc22 (and decomposed2 (cadr decomposed2)))
             ;; 合成後の文字が、合成前の2つの部首とは異なる
             ;; 新しい文字であることを確認する。
             ;; (string=?だと#fがあったときにエラーになるのでequal?を使用)
             (newchar
                (lambda (new)
                  (and
                    (not (equal? new c1))
                    (not (equal? new c2))
                    new))))
        (or
          ;; 引き算
          (and
            (equal? tc11 c2)
            (newchar tc12))
          (and
            (equal? tc12 c2)
            (newchar tc11))
          (and
            (equal? tc21 c1)
            (newchar tc22))
          (and
            (equal? tc22 c1)
            (newchar tc21))
          ;; 部品による足し算
          (let ((compose-newchar
                  (lambda (i1 i2)
                    (let ((res (tutcode-bushu-compose-sub i1 i2)))
                      (and res
                        (newchar res))))))
            (or
              (compose-newchar c1 tc22) (compose-newchar tc11 c2)
              (compose-newchar c1 tc21) (compose-newchar tc12 c2)
              (compose-newchar tc11 tc22) (compose-newchar tc11 tc21)
              (compose-newchar tc12 tc22) (compose-newchar tc12 tc21)))
          ;; 部品による引き算
          (and tc11
            (equal? tc11 tc21)
            (newchar tc12))
          (and tc11
            (equal? tc11 tc22)
            (newchar tc12))
          (and tc12
            (equal? tc12 tc21)
            (newchar tc11))
          (and tc12
            (equal? tc12 tc22)
            (newchar tc11)))))))

;;; 部首合成変換:c1とc2を合成してできる文字を探して返す。
;;; 指定された順番で見つからなかった場合は、順番を入れかえて探す。
;;; @param c1 1番目の部首
;;; @param c2 2番目の部首
;;; @return 合成後の文字。合成できなかったときは#f
(define (tutcode-bushu-compose-sub c1 c2)
  (and c1 c2
    (or
      (tutcode-bushu-compose c1 c2)
      (tutcode-bushu-compose c2 c1))))

;;; 部首合成変換:c1とc2を合成してできる文字を探して返す。
;;; @param c1 1番目の部首
;;; @param c2 2番目の部首
;;; @return 合成後の文字。合成できなかったときは#f
(define (tutcode-bushu-compose c1 c2)
  (let ((seq (rk-lib-find-seq (list c1 c2) tutcode-bushudic)))
    (and seq
      (car (cadr seq)))))

;;; 部首合成変換:等価文字を探して返す。
;;; @param c 検索対象の文字
;;; @return 等価文字。等価文字が見つからなかったときは元の文字自身
(define (tutcode-bushu-alternative c)
  (let ((alt (assoc c tutcode-bushudic-altchar)))
    (or
      (and alt (cadr alt))
      c)))

;;; 部首合成変換:文字を2つの部首に分解する。
;;; @param c 分解対象の文字
;;; @return 分解してできた2つの部首のリスト。分解できなかったときは#f
(define (tutcode-bushu-decompose c)
  (let ((lst
          (filter
            (lambda (elem)
              (string=? c (car (cadr elem))))
            tutcode-bushudic)))
    (and
      (not (null? lst))
      (car (caar lst)))))

;;; キーが押されたときの処理の振り分けを行う。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-key-press-handler pc key key-state)
  (if (control-char? key)
      (im-commit-raw pc)
      (begin
        (case (tutcode-context-state pc)
          ((tutcode-state-on)
           (tutcode-proc-state-on pc key key-state))
          ((tutcode-state-yomi)
           (tutcode-proc-state-yomi pc key key-state))
          ((tutcode-state-converting)
           (tutcode-proc-state-converting pc key key-state))
          ((tutcode-state-bushu)
           (tutcode-proc-state-bushu pc key key-state))
          (else
           (tutcode-proc-state-off pc key key-state)))
        (tutcode-update-preedit pc))))

;;; キーが離されたときの処理を行う。
;;; @param pc コンテキストリスト
;;; @param key 入力されたキー
;;; @param key-state コントロールキー等の状態
(define (tutcode-key-release-handler pc key key-state)
  (if (or (control-char? key)
	  (not (tutcode-context-on? pc)))
      ;; don't discard key release event for apps
      (im-commit-raw pc)))

;;; TUT-Code IMの初期化を行う。
(define (tutcode-init-handler id im arg)
  (tutcode-context-new id im))

(define (tutcode-release-handler pc)
  (tutcode-save-personal-dictionary))

(define (tutcode-reset-handler tc)
  (tutcode-flush tc))

(define (tutcode-focus-in-handler tc) #f)

(define (tutcode-focus-out-handler tc)
  (let ((rkc (tutcode-context-rk-context tc)))
    (rk-flush rkc)))

(define tutcode-place-handler tutcode-focus-in-handler)
(define tutcode-displace-handler tutcode-focus-out-handler)

(define (tutcode-get-candidate-handler tc idx) #f)
(define (tutcode-set-candidate-index-handler tc idx) #f)

(tutcode-configure-widgets)

;;; TUT-Code IMを登録する。
(register-im
 'tutcode
 "ja"
 "EUC-JP"
 (N_ "TUT-Code")
 (N_ "A kanji direct input method")
 #f
 tutcode-init-handler
 tutcode-release-handler
 context-mode-handler
 tutcode-key-press-handler
 tutcode-key-release-handler
 tutcode-reset-handler
 tutcode-get-candidate-handler
 tutcode-set-candidate-index-handler
 context-prop-activate-handler
 #f
 tutcode-focus-in-handler
 tutcode-focus-out-handler
 tutcode-place-handler
 tutcode-displace-handler
 )

;;; コード表をQwertyからDvorak用に変換する。
;;; @param qwerty Qwertyのコード表
;;; @return Dvorakに変換したコード表
(define (tutcode-rule-qwerty-to-dvorak qwerty)
  (map
    (lambda (elem)
      (cons
        (list
          (map
            (lambda (key)
              (cadr (assoc key tutcode-rule-qwerty-to-dvorak-alist)))
            (caar elem)))
        (cdr elem)))
    qwerty))

;;; QwertyからDvorakへの変換テーブル。
(define tutcode-rule-qwerty-to-dvorak-alist
  '(
    ;漢直で使うキー以外はコメントアウト
    ("1" "1")
    ("2" "2")
    ("3" "3")
    ("4" "4")
    ("5" "5")
    ("6" "6")
    ("7" "7")
    ("8" "8")
    ("9" "9")
    ("0" "0")
    ;("-" "[")
    ;("^" "]") ;106
    ("q" "'")
    ("w" ",")
    ("e" ".")
    ("r" "p")
    ("t" "y")
    ("y" "f")
    ("u" "g")
    ("i" "c")
    ("o" "r")
    ("p" "l")
    ;("@" "/") ;106
    ;("[" "=") ;106
    ("a" "a")
    ("s" "o")
    ("d" "e")
    ("f" "u")
    ("g" "i")
    ("h" "d")
    ("j" "h")
    ("k" "t")
    ("l" "n")
    (";" "s")
    ;(":" "-") ;106
    ("z" ";")
    ("x" "q")
    ("c" "j")
    ("v" "k")
    ("b" "x")
    ("n" "b")
    ("m" "m")
    ("," "w")
    ("." "v")
    ("/" "z")
    ;; shift
    ;("\"" "@") ;106
    ;("&" "^") ;106
    ;("'" "&") ;106
    ;("(" "*") ;106
    ;(")" "(") ;106
    ;("=" "{") ;106
    ;("~" "}") ;106
    ("Q" "\"")
    ("W" "<")
    ("E" ">")
    ("R" "P")
    ("T" "Y")
    ("Y" "F")
    ("U" "G")
    ("I" "C")
    ("O" "R")
    ("P" "L")
    ;("`" "?") ;106
    ;("{" "+") ;106
    ("A" "A")
    ("S" "O")
    ("D" "E")
    ("F" "U")
    ("G" "I")
    ("H" "D")
    ("J" "H")
    ("K" "T")
    ("L" "N")
    ("+" "S") ;106
    ;("*" "_") ;106
    ("Z" ":")
    ("X" "Q")
    ("C" "J")
    ("V" "K")
    ("B" "X")
    ("N" "B")
    ("M" "M")
    ("<" "W")
    (">" "V")
    ("?" "Z")
    (" " " ")
    ))

;;; tutcode-customで設定されたコード表のファイル名からコード表名を作って、
;;; 使用するコード表として設定する。
;;; 作成するコード表名は、ファイル名から".scm"をけずって、
;;; "-rule"がついてなかったら追加したもの。
;;; 例: "tutcode-rule.scm"→tutcode-rule
;;;     "tcode.scm"→tcode-rule
;;; @param filename tutcode-rule-filename
(define (tutcode-custom-load-rule! filename)
  (and
    (try-load filename)
    (let*
      ((basename (last (string-split filename "/")))
       ;; ファイル名から".scm"をけずる
       (bnlist (string-to-list basename))
       (codename
        (or
          (and
            (> (length bnlist) 4)
            (string=? (string-list-concat (list-head bnlist 4)) ".scm")
            (string-list-concat (list-tail bnlist 4)))
          basename))
       ;; "-rule"がついてなかったら追加
       (rulename
        (or
          (and
            (not (string=? (last (string-split codename "-")) "rule"))
            (string-append codename "-rule"))
          codename)))
      (and rulename
        (symbol-bound? (string->symbol rulename))
        (set! tutcode-rule
          (eval (string->symbol rulename) (interaction-environment)))))))

;;; tutcode-key-customで設定された交ぜ書き/部首合成変換開始のキーシーケンスを
;;; コード表に反映する
(define (tutcode-custom-set-mazegaki/bushu-start-sequence!)
  (let*
    ((make-subrule
      (lambda (keyseq cmd)
        (if
          (and
            keyseq
            (> (string-length keyseq) 0))
          (let ((keys (reverse (string-to-list keyseq))))
            (list (list (list keys) cmd)))
          #f)))
     (subrule ()))
    (set! subrule
      (make-subrule tutcode-mazegaki-start-sequence '(tutcode-mazegaki-start)))
    (set! subrule
      (append subrule
        (make-subrule tutcode-bushu-start-sequence '(tutcode-bushu-start))))
    (tutcode-rule-set-sequences! subrule)))

;;; コード表の一部の定義を上書き変更/追加する。~/.uimからの使用を想定。
;;; 呼び出し時にはtutcode-rule-userconfigに登録しておくだけで、
;;; 実際にコード表に反映するのは、tutcode-context-new時。
;;;
;;; (tutcode-rule-filenameの設定が、uim-prefと~/.uimのどちらで行われた場合でも
;;;  ~/.uimでのコード表の一部変更が同じ記述でできるようにするため。
;;;  コード表ロード後のhookを用意した方がいいかも)。
;;;
;;; 呼び出し例:
;;;   (tutcode-rule-set-sequences!
;;;     '(((("d" "l" "u")) ("づ" "ヅ"))
;;;       ((("d" "l" "d" "u")) ("っ" "ッ"))))
;;; @param rules キーシーケンスと入力される文字のリスト
(define (tutcode-rule-set-sequences! rules)
  (set! tutcode-rule-userconfig
    (append rules tutcode-rule-userconfig)))

;;; コード表の上書き変更/追加のためのtutcode-rule-userconfigを
;;; コード表に反映する。
(define (tutcode-rule-commit-sequences! rules)
  ;; コード表の検索はリニアに行われるので、リストの先頭に入れるだけで上書きもOK
  (if (not (null? rules))
    (set! tutcode-rule (append rules tutcode-rule))))
