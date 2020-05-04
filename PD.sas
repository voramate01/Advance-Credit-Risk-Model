libname d '';

data mortgage2;
set d.mortgage2;
run;

proc surveyselect data=mortgage2 samprate=0.8 outall seed=12345 out=mortgage3;
samplingunit id;
run;

/* Creates training and testing samples */

data train;
set mortgage3;
where selected=1;
run;

data test;
set mortgage3;
where selected=0;
run;


/* linear regression model */

proc reg data=train;
model default_time = mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3/
selection=stepwise slentry=0.05 slstay=0.01;
store out=model_linear;
run;

/* cloglog model */

proc logistic data=train descending;
model default_time = mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3/
link=cloglog selection=stepwise slentry=0.05 slstay=0.01;
store out=model_cloglog;
run;

/* logistic model */

proc logistic data=train descending;
model default_time = mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3/
selection=stepwise slentry=0.05 slstay=0.01;
store out=model_logistic;
run;

/* probit model */

proc logistic data=train descending;
model default_time = mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3/
link=probit selection=stepwise slentry=0.05 slstay=0.01;
store out=model_probit;
run;

proc plm source=model_linear;
	score data=test out=testlinear;
run;

proc plm source=model_linear;
	score data=train out=trainlinear;
run;

proc plm source=model_cloglog;
	score data=test out=testcloglog;
run;

proc plm source=model_logistic;
	score data=test out=testlogistic;
run;

proc plm source=model_probit;
	score data=test out=testprobit;
run;

proc sort data=test;
by time;
run;

proc means data=test;
by time;
output out=means mean(default_time)=default_time;
run;

ods graphics on;
proc univariate data=means;
	histogram default_time;
run;
ods graphics off;

data Testlinear;
set Testlinear;
sqerror_linear=(predicted-default_time)**2;
run;

PROC LOGISTIC data = trainlinear PLOTS(ONLY)=ROC;
CLASS default_time;
MODEL default_time = predicted;
RUN;

/*Level 1 Backtesting*/
PROC UNIVARIATE data = Testlinear noprint;
HISTOGRAM predicted;
RUN;

PROC LOGISTIC data = Testlinear PLOTS(ONLY)=ROC;
CLASS default_time;
MODEL default_time = predicted;
RUN;

PROC CORR DATA = Testlinear Pearson Spearman Kendall;
VAR default_time predicted;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=Testlinear
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL default_time= predicted ;
RUN;


data Testcloglog;
set Testcloglog;
pdcloglog=1-exp(-exp(predicted));
sqerror_cloglog=(pdcloglog-default_time)**2;
run;


/*Level 1 Backtesting*/
PROC UNIVARIATE data = Testcloglog noprint;
HISTOGRAM pdcloglog;
RUN;

PROC LOGISTIC data = Testcloglog PLOTS(ONLY)=ROC;
CLASS default_time;
MODEL default_time = pdcloglog;
RUN;

PROC CORR DATA = Testcloglog Pearson Spearman Kendall;
VAR default_time pdcloglog;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=Testcloglog
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL default_time= pdcloglog ;
RUN;

data Testlogistic;
set Testlogistic;
pdlogistic=1/(1+exp(-predicted));
sqerror_logistic=(pdlogistic-default_time)**2;
run;

/*Level 1 Backtesting*/
PROC UNIVARIATE data = Testlogistic noprint;
HISTOGRAM pdlogistic;
RUN;

PROC LOGISTIC data = Testlogistic PLOTS(ONLY)=ROC;
CLASS default_time;
MODEL default_time = pdlogistic;
RUN;

PROC CORR DATA = Testlogistic Pearson Spearman Kendall;
VAR default_time pdlogistic;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=Testlogistic
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL default_time= pdlogistic ;
RUN;

data Testprobit;
set Testprobit;
pdprobit=probnorm(predicted);
sqerror_probit=(pdprobit-default_time)**2;
run;


/*Level 1 Backtesting*/
PROC UNIVARIATE data = Testprobit noprint;
HISTOGRAM pdprobit;
RUN;

PROC LOGISTIC data = Testprobit PLOTS(ONLY)=ROC;
CLASS default_time;
MODEL default_time = pdprobit;
RUN;

PROC CORR DATA = Testprobit Pearson Spearman Kendall;
VAR default_time pdprobit;
RUN;

/*Level 2 Backtesting*/

PROC REG DATA=Testprobit
PLOTS(MAXPOINTS= 10000 STATS= ALL)= (CRITERIA QQ);
MODEL default_time= pdprobit ;
RUN;

data all;
	set Testprobit;
	set Testlogistic;
	set Testcloglog;
	set Testlinear;
run;


proc means data=Testlinear;
var predicted default_time sqerror_linear;
run;

proc means data=Testprobit;
var pdprobit default_time sqerror_probit;
run;

proc means data=Testcloglog;
var pdcloglog default_time sqerror_cloglog;
run;

proc means data=Testlogistic;
var pdlogistic default_time sqerror_logistic;
run;

proc sort data=testprobit;
by time;
run;

proc means data=testprobit;
by time;
output out=meansprobit mean(default_time pdprobit)=default_time pdprobit;
run;

proc sort data=testlogistic;
by time;
run;

proc means data=testlogistic;
by time;
output out=meanslogistic mean(default_time pdlogistic)=default_time pdlogistic;
run;

proc sort data=testcloglog;
by time;
run;

proc means data=testcloglog;
by time;
output out=meanscloglog mean(default_time pdcloglog)=default_time pdcloglog;
run;

proc sort data=testlinear;
by time;
run;

proc means data=testlinear;
by time;
output out=meanslinear mean(default_time predicted)=default_time predicted;
run;


proc sort data=meansprobit; by time; run;
proc sort data=meanslogistic; by time; run;
proc sort data=meanscloglog; by time; run;
proc sort data=meanslinear; by time; run;


data class;
	set meansprobit;
	set meanslogistic;
	set meanscloglog;
	set meanslinear;
run;

ods graphics on;
axis1 order=(0 to 60 by 5) label=('time');
axis2 order=(0 to 0.06 by 0.01) label=('DR and PD');
symbol1 interpol=spline width=2 value=triangle c=blue;
symbol2 interpol=spline width=2 value=circle c=red;
symbol3 interpol=spline width=2 value=square c=black;
symbol4 interpol=spline width=2 value= star c=green;
symbol5 interpol=spline width=2 value=oval c=yellow;

legend1 label=none shape=symbol(4,2) position=(bottom outside);

proc gplot data=class;
plot (default_time pdprobit pdlogistic pdcloglog predicted)*time/overlay haxis=axis1 vaxis=axis2 legend=legend1;
run;

ods graphics off;

data class;
	set class;
	errprobit = (pdprobit-default_time)**2;
	errlogistic = (pdlogistic-default_time)**2;
	errcloglog = (pdcloglog-default_time)**2;
	errpredicted = (predicted-default_time)**2;
run;

ods rtf;
proc means data=class;
var errprobit errlogistic errcloglog errpredicted;
run;
ods rtf close;



libname out 'C:/Users/nirav/Desktop/Final Project(1)';
data out.;
	set mortgage;
run;


proc plm source=model_probit;
	score data=mortgage3 out=probitall;
run;

data probitall;
set probitall;
pdprobit=probnorm(predicted);
sqerror_probit=(pdprobit-default_time)**2;
loss=0;
if default_time=1 then loss=balance_time;
run;

proc sort data=probitall;
by time;
run;

proc means data=probitall;
by time;
output out=meansprobitall mean(default_time pdprobit)=default_time pdprobit sum(balance_orig_time balance_time loss)=balance_orig_time balance_time loss;
run;

data meansead;
set d.meanslcf_bytime;
run;

data meansprobitead;
	merge meansprobitall meansead;
	by time;
run;

data meansprobitead;
set meansprobitead;
if time = 1 then predicted = 0.9477601;
if time = 2 then predicted = 0.9477601;
if time = 3 then predicted = 0.9477601;
if time = 4 then predicted = 0.9477601;
explossbeforerecovery = pdprobit*balance_orig_time*predicted;
explosswithrecovery = pdprobit*balance_orig_time*predicted*0.1246076;
percerrorloss = (explossbeforerecovery-loss)/loss;
run;

ods graphics on;
axis1 order=(0 to 60 by 5) label=('time');
axis2 order=(0 to 300000000 by 50000000) label=('Loss');
symbol1 interpol=spline width=2 value=triangle c=blue;
symbol2 interpol=spline width=2 value=circle c=red;
symbol3 interpol=spline width=2 value=square c=black;

legend1 label=none shape=symbol(4,2) position=(bottom outside);

proc gplot data=meansprobitead;
plot (loss explossbeforerecovery explosswithrecovery)*time/overlay haxis=axis1 vaxis=axis2 legend=legend1;
run;

ods graphics off;

ods graphics on;
axis1 order=(0 to 60 by 5) label=('time');
axis2 order=(-1 to 1.5 by 0.25) label=('Estimate Error');
symbol1 interpol=spline width=2 value=triangle c=blue;

legend1 label=none shape=symbol(4,2) position=(bottom outside);

proc gplot data=meansprobitead;
plot (percerrorloss)*time/overlay haxis=axis1 vaxis=axis2 legend=legend1;
run;

ods graphics off;


/* VIF */
ods rtf;
proc reg data=mortgage3;
model default_time = mat_time balance_orig_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index vix_index cpi_index fed_funds_rate ism cpr /
vif;
run;
ods rtf close;

ods rtf;
proc logistic data=train descending;
model default_time = mat_time balance_time LTV_time interest_rate_time hpi_time uer_time REtype_CO_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index vix_index cpi_index cpi_index_lag1 cpi_index_lag3 fed_funds_rate ism_lag1 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3/
link=probit;
run;
ods rtf close;
