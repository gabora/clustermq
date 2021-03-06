% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Q.r
\name{Q}
\alias{Q}
\title{Queue function calls on the cluster}
\usage{
Q(fun, ..., const = list(), expand_grid = FALSE, seed = 128965,
  memory = 4096, n_jobs = NULL, job_size = NULL, split_array_by = NA,
  fail_on_error = TRUE, log_worker = FALSE, wait_time = NA,
  chunk_size = NA)
}
\arguments{
\item{fun}{A function to call}

\item{...}{Objects to be iterated in each function call}

\item{const}{A list of constant arguments passed to each function call}

\item{expand_grid}{Use all combinations of arguments in `...`}

\item{seed}{A seed to set for each function call}

\item{memory}{The amount of Mb to request from LSF; default: 1 Gb}

\item{n_jobs}{The number of LSF jobs to submit; upper limit of jobs
if job_size is given as well}

\item{job_size}{The number of function calls per job}

\item{split_array_by}{The dimension number to split any arrays in `...`; default: last}

\item{fail_on_error}{If an error occurs on the workers, continue or fail?}

\item{log_worker}{Write a log file for each worker}

\item{wait_time}{Time to wait between messages; set 0 for short calls
defaults to 1/sqrt(number_of_functon_calls)}

\item{chunk_size}{Number of function calls to chunk together
defaults to 100 chunks per worker or max. 10 kb per chunk}
}
\value{
A list of whatever `fun` returned
}
\description{
Queue function calls on the cluster
}

