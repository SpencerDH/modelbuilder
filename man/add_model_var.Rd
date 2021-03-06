% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_model_var.R
\name{add_model_var}
\alias{add_model_var}
\title{A helper function that adds a variable to the shiny UI elements of the build tab}
\usage{
add_model_var(values, output)
}
\arguments{
\item{values}{a shiny variable keeping track of UI elements}

\item{output}{shiny output structure}
}
\value{
No direct return. output structure is modified to contain text for display in a Shiny UI
}
\description{
This function adds inputs for a new variable.
This is a helper function called by the shiny app.
}
\details{
This function is called by the Shiny server to produce the Shiny input UI elements for the build tab.
}
\author{
Andreas Handel
}
