; ABOUT:
;   Provides path manipulation and indexing functions
;
; DEPENDS:
; ALL() utils[env]
(local env (require :tangerine.utils.env))
(local p {})

;; -------------------- ;;
;;        Utils         ;;
;; -------------------- ;;
(lambda p.shortname [path]
  "shortens absolute 'path' for better readability."
  (or (path:match ".+/fnl/(.+)")
      (path:match ".+/lua/(.+)")
      (path:match ".+/(.+/.+)")))

(lambda p.resolve [path]
  "resolves 'path' to POSIX complaint path."
  (vim.fn.resolve (vim.fn.expand path)))


;; ------------------------- ;;
;;     Path Transformers     ;;
;; ------------------------- ;;
(local vimrc-out (-> (env.get :target) (.. "tangerine_vimrc.lua")))

(lambda p.from-x-to-y [path [from ext1] [to ext2]]
  "changes 'path's extension and parent-dir from 'ext1' to 'ext2'."
  (let [from (env.get from)
        from (from:gsub "%p" "%%%1")
        to   (env.get to)
        to (to:gsub "%p" "%%%1")
        path (path:gsub (.. ext1 "$") ext2)]
       (if (vim.startswith path from)
           (path:gsub from to)
           :else
           (path:gsub (.. "/" ext1 "/") (.. "/" ext2 "/"))))  )

(lambda p.target [path]
  "converts fnl:'path' to valid target path."
  (let [vimrc (env.get :vimrc)]
    (if (= path vimrc)
        vimrc-out
        :else
        (p.from-x-to-y path [:source "fnl"] [:target "lua"]))))

(lambda p.source [path]
  "converts lua:'path' to valid source path."
  (let [vimrc (env.get :vimrc)]
    (if (= path vimrc-out)
        vimrc
        :else
        (p.from-x-to-y path [:target "lua"] [:source "fnl"]))))


;; -------------------- ;;
;;         Vim          ;;
;; -------------------- ;;
(lambda p.goto-output []
  "open lua:target of current fennel buffer."
  (let [source (vim.fn.expand :%:p)
        target (p.target source)]
    (if (and (= 1 (vim.fn.filereadable target))
             (not= source target))
        (vim.cmd (.. "edit" target))
        :else
        (print "[tangerine]: error in goto-output, target not readable."))))


;; -------------------- ;;
;;       Indexers       ;;
;; -------------------- ;;
(lambda p.wildcard [dir pat]
  "expands wildcard 'pat' inside of 'dir' and return array of paths."
  (vim.fn.glob (.. dir pat) 0 1))

(fn p.list-fnl-files []
  "return array of .fnl files present in source dir."
  (let [source (env.get :source)
        out    (p.wildcard source "**/*.fnl")]
    (vim.tbl_filter #(not (string.find $1 "macros.fnl$")) out)))

(fn p.list-lua-files []
  "return array of .fnl files present in target dir."
  (let [target (env.get :target)
        out    (p.wildcard target "**/*.lua")]
    out))


:return p
