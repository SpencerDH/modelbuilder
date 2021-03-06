#' Create an ODE simulation model
#'
#' This function takes as input a modelbuilder model and writes code
#' for an ODE simulator implemented with deSolve
#'
#' @description The model needs to adhere to the structure specified by the modelbuilder package
#' models built using the modelbuilder package automatically have the right structure
#' a user can also build a model list structure themselves following the specifications
#' if the user provides a file name, this file needs to contain an object called 'model'
#' and contain a valid modelbuilder model structure
#' @param mbmodel modelbuilder model structure, either as list object or file name
#' @param location a filename and path to save the simulation code to. Default is current directory.
#' @return The function does not return anything
#' Instead, it writes an R file into the specified directory
#' this R file contains a deSolve implementation of the model
#' the name of the file is simulate_model$title_ode.R
#' @author Andreas Handel
#' @export

generate_ode <- function(mbmodel, location = NULL)
{
    #if the model is passed in as a file name, load it
    #otherwise, it is assumed that 'mbmodel' is a list structure of the right type
    if (is.character(mbmodel)) {load(mbmodel)}

    #if location is supplied, that's where the code will be saved to
    if (is.null(location))
    {
        savepath = paste0("./simulate_",gsub(" ","_",mbmodel$title),"_ode.R")
    }
    else
    {
        #the name of the function produced by this script is simulate_ + "model title" + "_ode.R"
        savepath <- location #default is current directory for saving the R function
    }

    nvars = length(mbmodel$var)  #number of variables/compartments in model
    npars = length(mbmodel$par)  #number of parameters in model
    ntime = length(mbmodel$time) #numer of parameters for time
    #text for model description
    #all this should be provided in the model sctructure
    sdesc=paste0("#' ",mbmodel$title,"\n#' \n")
    sdesc=paste0(sdesc,"#' ",mbmodel$description,"\n#' \n")
    sdesc=paste0(sdesc,"#' @details ",mbmodel$details, "\n")
    sdesc=paste0(sdesc,"#' This code is based on a dynamical systems model created by the modelbuilder package.  \n")
    sdesc=paste0(sdesc,"#' The model is implemented here as a set of ordinary differential equations, \n")
    sdesc=paste0(sdesc,"#' using the deSolve package. \n")
    sdesc=paste0(sdesc,"#' @param vars vector of starting conditions for model variables: \n")
    sdesc=paste0(sdesc,"#' \\itemize{ \n")
    for (n in 1:nvars)
    {
        sdesc=paste0(sdesc,"#' \\item ", mbmodel$var[[n]]$varname, ' : starting value for ',mbmodel$var[[n]]$vartext, "\n")
    }
    sdesc=paste0(sdesc,"#' } \n")
    sdesc=paste0(sdesc,"#' @param pars vector of values for model parameters: \n")
    sdesc=paste0(sdesc,"#' \\itemize{ \n")
    for (n in 1:npars)
    {
        sdesc=paste0(sdesc,"#' \\item ", mbmodel$par[[n]]$parname," : ", mbmodel$par[[n]]$partext, "\n")
    }
    sdesc=paste0(sdesc,"#' } \n")
    sdesc=paste0(sdesc,"#' @param times vector of values for model times: \n")
    sdesc=paste0(sdesc,"#' \\itemize{ \n")
    for (n in 1:ntime)
    {
        sdesc=paste0(sdesc,"#' \\item ", mbmodel$time[[n]]$timename," : ", mbmodel$time[[n]]$timetext, "\n")
    }
    sdesc=paste0(sdesc,"#' } \n")
    sdesc=paste0(sdesc,"#' @param ... other arguments for possible pass-through \n")
    sdesc=paste0(sdesc,"#' @return The function returns the output as a list. \n")
    sdesc=paste0(sdesc,"#' The time-series from the simulation is returned as a dataframe saved as list element \\code{ts}. \n")
    sdesc=paste0(sdesc,"#' The \\code{ts} dataframe has one column per compartment/variable. The first column is time.   \n")
    sdesc=paste0(sdesc,"#' @examples  \n")
    sdesc=paste0(sdesc,"#' # To run the simulation with default parameters:  \n")
    sdesc=paste0(sdesc,"#' result <- simulate_",gsub(" ","_",mbmodel$title),"_ode()", " \n")
    sdesc=paste0(sdesc,"#' @section Warning: ","This function does not perform any error checking. So if you try to do something nonsensical (e.g. have negative values for parameters), the code will likely abort with an error message.", "\n")
    sdesc=paste0(sdesc,"#' @section Model Author: ",mbmodel$author, "\n")
    sdesc=paste0(sdesc,"#' @section Model creation date: ",mbmodel$date, "\n")
    sdesc=paste0(sdesc,"#' @section Code Author: generated by the \\code{generate_ode} function \n")
    sdesc=paste0(sdesc,"#' @section Code creation date: ",Sys.Date(), "\n")
    sdesc=paste0(sdesc,"#' @export \n \n")

    ##############################################################################
    #the next block of commands produces the ODE function required by deSolve
    sode = "  #Block of ODE equations for deSolve \n"
    sode = paste0(sode,"  ", gsub(" ","_",mbmodel$title),'_ode_fct <- function(t, y, parms) \n  {\n')
    sode = paste0(sode,"    with( as.list(c(y,parms)), { #lets us access variables and parameters stored in y and parms by name \n")

    #text for equations and final list
    seqs= "    #StartODES\n"
    slist="    list(c("
    for (n in 1:nvars)
    {
        seqs = paste0(seqs,"    #",mbmodel$var[[n]]$vartext,' : ', paste(mbmodel$var[[n]]$flownames, collapse = ' : '),' :\n')
        seqs = paste0(seqs,'    d',mbmodel$var[[n]]$varname,' = ',paste(mbmodel$var[[n]]$flows, collapse = ' '), '\n' )
        slist = paste0(slist, paste0('d',mbmodel$var[[n]]$varname,','))
    }
    sode=paste0(sode,seqs)
    sode = paste0(sode,"    #EndODES\n")
    slist = substr(slist,1,nchar(slist)-1) #get rid of final comma
    slist = paste0(slist,')) \n') #close parantheses
    sode=paste0(sode,slist)
    sode = paste0(sode, "  } ) } #close with statement, end ODE code block \n \n")
    #finish block that creates the ODE function
    ##############################################################################


    ##############################################################################
    #this creates the lines of code for the main function
    #text for main body of function
    varstring = "vars = c("
    for (n in 1:nvars)
    {
        varstring=paste0(varstring, mbmodel$var[[n]]$varname," = ", mbmodel$var[[n]]$varval,', ')
    }
    varstring = substr(varstring,1,nchar(varstring)-2)
    varstring = paste0(varstring,'), ') #close parantheses

    parstring = "pars = c("
    for (n in 1:npars)
    {
        parstring=paste0(parstring, mbmodel$par[[n]]$parname," = ", mbmodel$par[[n]]$parval,', ')
    }
    parstring = substr(parstring,1,nchar(parstring)-2)
    parstring = paste0(parstring,'), ') #close parantheses

    timestring = "times = c("
    for (n in 1:ntime)
    {
        timestring=paste0(timestring, mbmodel$time[[n]]$timename," = ", mbmodel$time[[n]]$timeval,', ')
    }
    timestring = substr(timestring,1,nchar(timestring)-2)
    timestring = paste0(timestring,') ') #close parantheses

    stitle = paste0('simulate_',gsub(" ","_",mbmodel$title),"_ode <- function(",varstring, parstring, timestring,') \n{ \n')

    smain = "  #Main function code block \n"

    smain = paste0(smain,'  timevec=seq(times[1],times[2],by=times[3]) \n')
    smain = paste0(smain,'  odeout = deSolve::ode(y = vars, parms = pars, times = timevec,  func = ',gsub(" ","_",mbmodel$title),'_ode_fct) \n')
    smain = paste0(smain,'  result <- list() \n');
    smain = paste0(smain,'  result$ts <- as.data.frame(odeout) \n')
    smain = paste0(smain,'  return(result) \n')
    smain = paste0(smain,'} \n')
    #finish block that creates main function part
    ##############################################################################
    #write all text blocks to file
    sink(savepath)
    cat(sdesc)
    cat(stitle)
    cat(sode)
    cat(smain)
    sink()
}
