libname data '';

data lgd;
set data.lgd;
run;

proc surveyselect data=lgd samprate=0.8 outall seed=12345 out=lgd;
run;

/**** Transformed Linear Regression ***/

/*logistic*/
ODS GRAPHICS ON;
proc reg data=lgd(where=(selected=0)) outest=reg_log;
model y_logistic=LTV purpose1 / details=all; 
store out=model_log;
run;

PROC PLM SOURCE=model_log;
SCORE DATA = lgd(where=(selected=1)) OUT = val_log;
RUN;

data val_log;
set val_log;
pred_lgd=1/(1+exp(-predicted));
run;

/*Level 1 Backtesting*/
PROC UNIVARIATE data = val_log noprint;
HISTOGRAM lgd_time pred_lgd / KERNEL(c = 0.25 0.50 0.75 1.00
l = 1 20 2 34
NOPRINT);
RUN;

DATA val_log;
SET val_log;
D_LGD = 0;
IF lgd_time > 0.2312 THEN D_LGD = 1;
RUN;

PROC LOGISTIC data = val_log PLOTS(ONLY)=ROC;
CLASS D_LGD;
MODEL D_LGD = pred_lgd;
RUN;

PROC CORR DATA = val_log Pearson Spearman Kendall;
VAR lgd_time pred_lgd;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=val_log
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL lgd_time= pred_lgd ;
RUN;

/*probit*/

ODS GRAPHICS ON;
proc reg data=lgd(where=(selected=0)) outest=reg_prob;
model y_probit=LTV purpose1 / details=all; 
store out=model_prob;
run;

PROC PLM SOURCE=model_prob;
SCORE DATA = lgd(where=(selected=1)) OUT = val_prob;
RUN;

data val_prob;
set val_prob;
pred_lgd=probnorm(predicted);
run;

/*Level 1 Backtesting*/
PROC UNIVARIATE data = val_prob noprint;
HISTOGRAM lgd_time pred_lgd / KERNEL(c = 0.25 0.50 0.75 1.00
l = 1 20 2 34
NOPRINT);
RUN;

DATA val_prob;
SET val_prob;
D_LGD = 0;
IF lgd_time > 0.2312 THEN D_LGD = 1;
RUN;

PROC LOGISTIC data = val_prob PLOTS(ONLY)=ROC;
CLASS D_LGD;
MODEL D_LGD = pred_lgd;
RUN;

PROC CORR DATA = val_prob Pearson Spearman Kendall;
VAR lgd_time pred_lgd;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=val_prob
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL lgd_time= pred_lgd ;
RUN;

/*** Nonlinear Regression ***/

proc nlmixed data=lgd(where=(selected=0)) tech=trureg;
parms b0=0 b1=0 sigma=1;
xb=b0+b1*LTV;
mu=1/(1+exp(-xb));
lh=pdf('normal', lgd_time, mu, sigma);
ll=log(lh);
model lgd_time~general(ll);
run;

/*** Fractional Logit Regression ***/

proc nlmixed data=lgd2(where=(selected=0)) tech=trureg;
parms b0=0 b1=0;
xb=b0+b1*LTV;
mu=1/(1+exp(-xb));
lh=(mu**lgd_time)*((1-mu)**(1-lgd_time));
ll=log(lh);
model lgd_time~general(ll);
run;

/*** Beta Regression ***/

ods graphics on;
proc nlmixed data=lgd(where=(selected=0)) tech=trureg;
parms b0=0 b1=0.001 b2=0.0001 c0=0 c1=0.001 c2=0.0001;

*linear predictors;
xb=b0+b1*LTV+b2*purpose1;
wc=c0+c1*LTV+c2*purpose1;
mu=1/(1+exp(-xb));
delta=exp(wc);

*transform to std parameterization;
alpha=mu*delta;
beta=(1-mu)*delta;

*loglikelihood;

lh=(Gamma(alpha+beta)/(Gamma(alpha)*Gamma(beta))*(lgd_time**(alpha-1))*((1-lgd_time)**(beta-1)));
ll=log(lh);
model lgd_time~general(ll);
predict mu out=out_mu;
predict delta out=out_delta;
run;

/*Level 1 Backtesting*/
PROC UNIVARIATE data = out_mu noprint;
HISTOGRAM lgd_time pred / KERNEL(c = 0.25 0.50 0.75 1.00
l = 1 20 2 34
NOPRINT);
RUN;

DATA out_mu;
SET out_mu;
D_LGD = 0;
IF lgd_time > 0.2312 THEN D_LGD = 1;
RUN;

PROC LOGISTIC data = out_mu PLOTS(ONLY)=ROC;
CLASS D_LGD;
MODEL D_LGD = pred;
RUN;

PROC CORR DATA = out_mu Pearson Spearman Kendall;
VAR lgd_time pred;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=out_mu
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL lgd_time= pred;
RUN;
