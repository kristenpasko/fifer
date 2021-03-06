##' Compare the fits of two models
##'
##' Compare the fits of two models
##'	
##' Compare the fits of two models
##' @param formula A formula that can be used in flexplot. The variables inside must not include variables outside the fitted models. 
##' @param data The dataset containing the variables in formula
##' @param model1 The fitted model object (e.g., lm) containing the variables specified in the formula
##' @param model2 The second fitted model object (e.g., lm) containing the variables specified in the formula
##' @param return.preds Should the function return the predictions instead of a graphic? Defaults to F
##' @param silent Should R tell you how it's handling the variables in the model that are not in the formula? Defaults to F. 
##' @param report.se Should standard errors be reported alongside the estimates? Defaults to F. 
##' @author Dustin Fife
##' @export
##' @examples
##' #not yet
compare.fits = function(formula, data, model1, model2=NULL, return.preds=F, silent=F, report.se=F,...){

	#### if mod2 is null..
	if (is.null(model2)){
		model2 = model1
		old.mod = 1
	} else {
		old.mod = 0
	}

	#### extract the terms from each model
	terms.mod1 = attr(terms(model1), "term.labels")
	terms.mod2 = attr(terms(model2), "term.labels")
		
	#### check if models have the same terms
	if (length(which(!(terms.mod1 %in% terms.mod2)))>0 | length(which(!(terms.mod2 %in% terms.mod1)))>0){
		warning("You should probably have the same predictors in both models for a better comparison.")
	}

	##### extract variable names
	variables = all.vars(formula)
    outcome = variables[1]
    predictors = variables[-1]
    

	#### create random column just to make the applies work (yeah, it's hacky, but it works)
    data$reject = 1:nrow(data); data$reject2 = 1:nrow(data)
    predictors = c(predictors, "reject", "reject2")

    #### get variable types
    numb = names(which(unlist(lapply(data[,predictors], is.numeric))))
    cat = names(which(!(unlist(lapply(data[,predictors], is.numeric)))))
    
    ##### make "quadriture" points for quant variables
    var.mins = apply(data[, numb], 2, min, na.rm=T)
    var.max = apply(data[, numb], 2, max, na.rm=T)    
    min.max = data.frame(var.mins, var.max)
	f = function(d){seq(from=d[1], to=d[2], length.out=10)}
	min.max = as.list(as.data.frame((apply(min.max, 1, f))))

    #### get unique values for categorical vars
    if (length(cat)==1){
    	un.vars = lapply(data[cat], unique)    	
    } else {
		un.vars =lapply(data[,cat], unique); names(un.vars) = cat
	}

    
    #### combine into one dataset
    all.vars = c(min.max, un.vars)    
    #### get rid of extra variables
    tot.vars = length(predictors)
    rejects = grep("reject", names(all.vars))
	all.vars = all.vars[-rejects]
	pred.values = expand.grid(all.vars)
	
	
	model1.type = class(model1)[1]
	model2.type = class(model2)[1]


	##### look for interactions and remove them
	if (length(grep(":", terms.mod1))>0){
		terms.mod1 = terms.mod1[-grep(":", terms.mod1)]
		model1.type = "interaction"
	}
	if (length(grep(":", terms.mod2))>0){
		terms.mod2 = terms.mod2[-grep(":", terms.mod1)]
		model2.type = "interaction"
	}	
	
	##### look for polynomials and remove them
	if (length(grep("^2", terms.mod1, fixed=T, value=T))>0){
		terms.mod1 = terms.mod1[-grep("^2", terms.mod1, fixed=T)]
		model1.type="polynomial"
	}
	if (length(grep("^2", terms.mod2, fixed=T, value=T))>0){
		terms.mod2 = terms.mod2[-grep("^2", terms.mod1, fixed=T)]
		model2.type="polynomial"
	}	
	
	
	#### if the outcome is an ordered factor...
		
	
	#### if it's not in model 1:
	#### input the mean (if numeric) or a value (if categorical)
	if (length(which(!(terms.mod1 %in% predictors)))>0){
		not.in.there = terms.mod1[which(!(terms.mod1 %in% predictors))]
		for (i in 1:length(not.in.there)){
			if (is.numeric(data[,not.in.there[i]])){
				if (!silent){cat(paste0("Note: You didn't choose to plot ", not.in.there[i], " so I am inputting the median\n"))}
				pred.values[,not.in.there[i]] = median(data[,not.in.there[i]], na.rm=T)
			} else {
				val = unique(data[,not.in.there[i]])[1]
				if (!silent){cat(paste0("Note: You didn't choose to plot ", not.in.there[i], " so I am inputting '", val, "'\n"))}
				pred.values[,not.in.there[i]] = val
			}
		}
	}
	

	#### generate predictions
	if (model1.type == "lmerMod" | model1.type == "glmerMod"){
		pred.mod1 = data.frame(prediction = predict(model1, pred.values, type="response", re.form=NA), model= model1.type)		
	} else if (model1.type == "polr"){
		pred.mod1 = data.frame(prediction = predict(model1, pred.values, type="class", re.form=NA), model= model1.type)		
	} else  {
		pred.mod1 = data.frame(prediction = predict(model1, pred.values, type="response", interval="confidence"), model= model1.type)		
	}
	

	if (model2.type == "lmerMod" | model2.type == "glmerMod"){
		pred.mod2 = data.frame(prediction = predict(model2, pred.values, type="response", re.form=NA), model= model2.type)		
	} else if (model2.type == "polr"){
		pred.mod2 = data.frame(prediction = predict(model2, pred.values, type="class", re.form=NA), model= model2.type)		
	} else {
		pred.mod2 = data.frame(prediction = predict(model2, pred.values, type="response"), model= model2.type, se.fit= report.se)		
	}
	
	#### convert polyr back to numeric (if applicable)
	if (model1.type == "polr" | model2.type == "polr"){
		data[,outcome] = as.numeric(as.character(data[,outcome]))		
		pred.mod1$prediction = as.numeric(as.character(pred.mod1$prediction))
		pred.mod2$prediction = as.numeric(as.character(pred.mod2$prediction))		
	}
	
	
	#### report one or two coefficients, depending on if they supplied it
	if (old.mod==0){
		prediction.model = rbind(pred.mod1, pred.mod2)
		prediction.model = cbind(pred.values, prediction.model)
	} else {
		prediction.model = pred.mod1
		prediction.model = cbind(pred.values, prediction.model)
	}

	#### eliminate those predictions that are higher than the range of the data
	if (!is.factor(data[,outcome])){
	min.dat = min(data[,outcome], na.rm=T); max.dat = max(data[,outcome], na.rm=T)
	if (length(which(prediction.model$prediction>max.dat)>0 | length(which(prediction.model$prediction<min.dat)))){
		prediction.model  = prediction.model[-which(prediction.model$prediction>max.dat | prediction.model$prediction<min.dat), ]
	}
	} else {
		#### if they supply a factor, convert it to a number!!!!!
		prediction.model$prediction = as.numeric(as.character(prediction.model$prediction))
	}



	#### create flexplot
	if (return.preds){
		prediction.model
	} else {
		flexplot(formula, data=data, prediction=prediction.model, suppress_smooth=T, se=F, ...)
	}	

}	