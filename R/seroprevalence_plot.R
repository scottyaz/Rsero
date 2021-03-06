#' @title Plot the seroprevalence by age 
#'
#' @description Plot the mean and 95 \%  confidence interval of the seroprevalence by age-class. Accepts as an input a \code{SeroData} object. If multiple \code{category} are defined, it will also compute the seroprevalence for each category.  
#' 
#' @author Nathanael Hoze \email{nathanael.hoze@gmail.com}
#' 
#' @param serodata An object of the class \code{SeroData}.
#' 
#' @param age_class Integer. The length in years of the age classes. Default = 10. 
#' 
#' @param YLIM Upper limit of the y-axis. Default = 1. The lower limit is set to 0. 
#' 
#' @return a list with plots of the seroprevalence for each category, or one plot if only one category is defined. 
#'
#' @export
#' @examples
#' 
#' dat  = data("one_peak_simulation")
#' seroprevalence.plot(serodata = dat)
#' 

seroprevalence.plot<- function(serodata, age_class = 10, YLIM = 1, ...){
  
  plots  <- NULL
  index.plot=0
  
  for(sampling_year in sort(unique(serodata$sampling_year))){
    for(cat in serodata$unique.categories){
      
      index.plot <- index.plot+1
      
      w <- which(serodata$sampling_year ==  sampling_year & serodata$category==cat, arr.ind = TRUE)[,1]
      #w <- as.matrix(which(serodata$sampling_year ==  sampling_year & serodata$category==cat, arr.ind = TRUE))[,1]
      
      if(length(w)>0){
        
        subdata <- subset(serodata,sub = w)
        histdata <- sero.age.groups(dat = subdata,age_class = age_class,YLIM=YLIM)
        
        g <- ggplot(histdata, aes(x=labels, y=mean)) + geom_point() + geom_segment(aes(x=labels,y=lower, xend= labels,yend=upper))
        g <- g + theme_classic()
        g <- g+theme(axis.text.x = element_text(size=12),
                     axis.text.y = element_text(size=12),
                     text=element_text(size=14))
        g <- g+xlab('Age')+ylab('Proportion seropositive')+ylim(0,YLIM)
        
        plots[[index.plot]]= g
        plots[[index.plot]]$category  = cat
        
        if(serodata$Ncategory>1){
          cat(sprintf('Category: %s \n',cat))
        }
      }
    }
    
  }
  
  if(length(plots)>1){
    rc <- plots
  } else {
    rc <- plots[[1]]
  }

    return(rc)
  
}

# get the seroprevalence (meanand 95%CI) for each age group
sero.age.groups <- function(dat,age_class,YLIM){
  
  age_categories <- seq(from = 0, to = dat$A, by = age_class)
  age_bin <- sapply(dat$age, function(x) tail(which(x-age_categories >= 0), 1L)) # find the closest element
  S <- as.integer(as.logical(dat$Y)) 
  S1 <- sapply(1:length(age_categories), function(x) length(which(age_bin==x)) )
  S2 <- sapply(1:length(age_categories), function(x) sum(S[which(age_bin==x)] ))
  C <- (rbind((age_categories[1:length(age_categories)-1]), (age_categories[2:length(age_categories)]-1)))
  
  df = data.frame(x=age_categories,y=S2/S1)
  
  G=matrix(NA,nrow =  dim(df)[1], ncol=3)
  
  
  for(j in seq(1,length(S1))){
    if(S1[j]>3){
      B= binom::binom.confint(x=S2[j],n = S1[j],methods = "exact")
      G[j,1]=B$lower
      G[j,2]=B$upper
      G[j,3]=B$mean
    } else {
      warning("not estimating mean and CI due to low sample size in a category")
    }
  }
  
  
  G[which(G >YLIM)] =YLIM
  mean_age =  c( (age_categories[1:length(age_categories)-1] +age_categories[2:length(age_categories)])/2, age_categories[length(age_categories)] ) 
  
  
  C <- (rbind((age_categories[1:length(age_categories)-1]), (age_categories[2:length(age_categories)]-1)))
  
  if(sum(C[1, ]-C[2, ]) == 0 ){ # means that the age categories are each 1 year long
    histo_label <- append(format(C[1, ]), paste(">=", tail(age_categories, n = 1), sep = ""))
  } else{
    histo_label <- append(apply(format(C), 2, paste, collapse = "-"), paste(">=", tail(age_categories, n = 1), sep = ""))
  }
  
  
  histdata <- data.frame(age = mean_age,
                         mean=G[,3],
                         lower = G[,1],
                         upper = G[, 2],
                         labels = factor(histo_label, levels=histo_label))
  
  return(histdata)
  
  
}



