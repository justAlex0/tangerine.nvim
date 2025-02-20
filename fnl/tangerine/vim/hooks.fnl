; ABOUT:
;   Defines autocmd hooks as described in ENV.
;
; DEPENDS:
; (-run)    api[init] -> _G.tangerine.api
; (-onsave) utils[env]
(local env (require :tangerine.utils.env))

(local hooks {})

;; -------------------- ;;
;;        Utils         ;;
;; -------------------- ;;
(lambda exec [...]
  "executes given multi-args as vim command."
  (vim.cmd (table.concat [...] " ")))

(lambda parse-autocmd [opts]
  "converts 'opts' containing [[group] cmd] chunks into valid autocmd."
  (let [groups (table.concat (table.remove opts 1) " ")]
       (values :au groups (table.concat opts " "))))

(lambda augroup [name ...]
  "defines augroup with 'name' and multi-args containing [[group] cmd] chunks."
  (exec :augroup name)
  (exec :au!)
  (each [idx val (ipairs [...])]
        (exec (parse-autocmd val)))
  (exec :augroup "END")
  :return true)

(local flat vim.tbl_flatten)
(local map  vim.tbl_map)


;; -------------------- ;;
;;         AUGS         ;;
;; -------------------- ;;
(lambda hooks.run []
  "base runner of hooks, calls compiler as defined in ENV."
  (if (env.get :compiler :clean)
      (_G.tangerine.api.clean.orphaned))
  (_G.tangerine.api.compile.all))

(local run-hooks ; lua wrapper around hooks.run
       "lua require 'tangerine.vim.hooks'.run()")

(lambda hooks.onsave []
  "runs everytime fennel files in source dirs are saved."
  (local pat [
    (env.get :vimrc)
    (.. (env.get :source) "*.fnl")
    (map #(.. $ "*.fnl") (env.get :rtpdirs))
    (map #(.. $ "*.fnl") (icollect [_ [s t] (ipairs (env.get :custom))] s))
  ])
  (augroup :tangerine-onsave
           [[:BufWritePost (table.concat (flat pat) ",")] run-hooks]))

(lambda hooks.onload []
  "runs when VimEnter event fires."
  (augroup :tangerine-onload
           [[:VimEnter "*"] run-hooks]))

(lambda hooks.oninit []
  "runs instantly on calling."
  :call (hooks.run))


:return hooks
