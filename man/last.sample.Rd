% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/last.sample.R
\name{last.sample}
\alias{last.sample}
\alias{lastsample}
\alias{lastSample}
\alias{one.row}
\alias{last.row}
\title{Return only one row per ID}
\usage{
last.sample(ID, sort.var = NULL, decreasing = TRUE, data, FUN = NULL,
  fun.var = NULL, ...)
}
\arguments{
\item{ID}{The name of the unique identifier, expressed as a string (e.g., "Match.Group")}

\item{sort.var}{The variable to be sorted on in order to take the first (or last) sample, expressed as a string.}

\item{decreasing}{How should the sort.var variable be sorted? Defaults to T.}

\item{data}{The dataset with multiple rows per individual}

\item{FUN}{What should be done with the multiple samples? This function can be used to extract the last 
(or first) sample using the decreasing/sort.var options, or a function can be performed (such as the mean)
on one or more columns. See examples.}

\item{fun.var}{If FUN if not null, the variable (or a vector of variables), expressed as strings to have the function
applied to.}

\item{...}{Other arguments passed to the chosen function.}
}
\value{
a new dataframe containing one row per ID
}
\description{
Often times, an individual has multiple observations in the dataset. \code{last.sample} will
loop through the entire dataset and return only one observation per individual, giving the
first (or last) draw for a person, or performing some function on the variable of interest.
}
\examples{
#### take only group 2 values
last.sample(ID="ID", sort.var="group", data=sleep)
#### take only group 1 values
last.sample(ID="ID", sort.var="group", decreasing=FALSE,data=sleep)
#### average group 1 and 2 values
last.sample(ID="ID", data=sleep, FUN=mean, fun.var="extra")
#### take the maximum extra value
last.sample(ID="ID", data=sleep, FUN=max, fun.var="extra")
#### take the mean of two columns extra value
sleep$group = as.numeric(as.character(sleep$group))
last.sample(ID="ID", data=sleep, FUN=mean, fun.var=c("group","extra"))
}
\author{
Dustin Fife
}
