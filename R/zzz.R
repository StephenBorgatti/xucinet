# The exporters in class-xucinet.R are plain functions, as UCINET users will
# type them. But igraph, network and tidygraph each own a generic that does the
# same job, and tidygraph's as_tbl_graph() would mask ours the moment a user
# calls library(tidygraph). So we also hang methods off those generics, which
# makes as.igraph(net) / as.network(net) / as_tbl_graph(net) work whichever
# package is on top of the search path.
#
# The generics live in Suggests packages, so they cannot be declared in
# NAMESPACE; they are registered here when (and if) the package turns up.

xucinet_as_igraph    <- function(x, ...) as_igraph(x, ...)
xucinet_as_network   <- function(x, ...) as_network(x, ...)
xucinet_as_tbl_graph <- function(x, ...) as_tbl_graph(x, ...)

# Base-R equivalent of rlang::s3_register(): register now if the package is
# already loaded, and on a hook in case it is loaded later. Deliberately avoids
# requireNamespace(), which would drag the Suggests package into every session.
register_s3_when_available <- function(pkg, generic, class, method) {
  register <- function(...) {
    ns <- asNamespace(pkg)
    if (!exists(generic, envir = ns, inherits = FALSE)) return(invisible(NULL))
    registerS3method(generic, class, method, envir = ns)
    invisible(NULL)
  }
  if (isNamespaceLoaded(pkg)) register()
  setHook(packageEvent(pkg, "onLoad"), register)
  invisible(NULL)
}

.onLoad <- function(libname, pkgname) {
  register_s3_when_available("igraph",    "as.igraph",    "xucinet", xucinet_as_igraph)
  register_s3_when_available("network",   "as.network",   "xucinet", xucinet_as_network)
  register_s3_when_available("tidygraph", "as_tbl_graph", "xucinet", xucinet_as_tbl_graph)
  invisible(NULL)
}
