#!/usr/bin/r

setwd("~/git/universe")

suppressMessages({
    library(data.table)
    library(jsonlite)
    library(git2r)
})

## -- nope, no a return object :-/
## cran <- data.table(dang::checkCRANStatus("edd@debian.org"))

db <- tools::CRAN_package_db()
setDT(db)
cranpackages <- db[grepl("edd@debian.org", Maintainer), .(Package, Maintainer)]
setnames(cranpackages, tolower(colnames(cranpackages)))

#universe <- fromJSON("packages_in_universe.json")
universe <- fromJSON("packages.json")
setDT(universe)

all <- universe[cranpackages, on=c("package","maintainer")]

newpackages <- all[is.na(available),]
for (i in seq_len(nrow(newpackages))) {
    pkg <- newpackages[[i, "package"]]
    dir <- file.path("..", tolower(pkg))
    exists <- dir.exists(dir)
    if (!exists) next
    rems <- remotes(dir)
    orig <- remote_url(dir)[[which(rems=="origin")]]
    httpurl <- gsub("git@(.*):(.*)/(.*)\\.git", "https://\\1/\\2/\\3", orig)
    ##cat("Package", pkg, dir, url, "\n")
    newpackages[i, `:=`(url=httpurl, available=TRUE)]
}

newall <- rbind(universe, newpackages)[order(package)]
setkey(newall, "package")

## 'other' missing ones
otherDirs <- system("grep -l \"^Maintainer: Dirk Eddelbuettel <edd\" ~/git/*/DESCRIPTION | cut -f5 -d/", intern=TRUE)
others <- data.table(dir=otherDirs, key="dir")
getPkg <- function(d) {
    dcf <- read.dcf(paste0("/home/edd/git/", d, "/DESCRIPTION"))
    dcf[[1, "Package"]]
}
others[ , package := getPkg(dir[1]), by="dir"]
setkey(others, "package")
newpkgs <- newall[others][is.na(available)]
newpkgs[]

## corrections
##
## 1) corels repo is rcppcorels
#newall[package=="corels", url:="https://github.com/corels/rcppcorels"]
##
## 2) additions
M <- newall[[1, "maintainer"]]
gitUrl <- function(p, o="eddelbuettel") sprintf("https://github.com/%s/%s", o, p)
#added <- list(data.frame(package="RcppAsioExample", maintainer=M, url=gitUrl("rcppasioexample"), available=TRUE))
#added <- list(data.frame(package="RcppGeiger", maintainer=M, url=gitUrl("rcppgeiger"), available=TRUE))
#added <- list(data.frame(package="RcppHyperDual", maintainer=M, url=gitUrl("rcpphyperdual"), available=TRUE))
#added <- list(data.frame(package="RcppBenchmark", maintainer=M, url=gitUrl("rcppbenchmark"), available=TRUE))
#added <- list(data.frame(package="RcppIconvExample", maintainer=M, url=gitUrl("rcppiconvexample"), available=TRUE))
#added <- list(data.frame(package="RcppKalman", maintainer=M, url=gitUrl("rcppkalman"), available=TRUE))
#added <- list(data.frame(package="RcppL1TF", maintainer=M, url=gitUrl("rcppl1tf"), available=TRUE))
#added <- list(data.frame(package="RcppLongLong", maintainer=M, url=gitUrl("rcpplonglong"), available=TRUE))
#added <- list(data.frame(package="RcppUTS", maintainer=M, url=gitUrl("rcpputs"), available=TRUE))
#added <- list(data.frame(package="bbb", maintainer=M, url=gitUrl("bbb"), available=TRUE))
#added <- list(data.frame(package="RcppTomlPlusPlus", maintainer=M, url=gitUrl("bbb"), available=TRUE))
#added <- list(data.frame(package="chshli", maintainer=M, url=gitUrl("chshli"), available=TRUE))
#added <- list(data.frame(package="ccptm", maintainer=M, url=gitUrl("cook-county-tax-model"), available=TRUE))
#added <- list(data.frame(package="curse", maintainer=M, url=gitUrl("curse"), available=TRUE))
#added <- list(data.frame(package="earthmovdist", maintainer=M, url=gitUrl("earthmovdist"), available=TRUE))
#added <- list(data.frame(package="lwplot", maintainer=M, url=gitUrl("lwplot"), available=TRUE))
added <- list(data.frame(package="minm", maintainer=M, url=gitUrl("minm"), available=TRUE))

newall <- rbind(newall, rbindlist(added))

cat(toJSON(newall[order(package)], pretty=TRUE, auto_unbox=TRUE), file="packages.json")
