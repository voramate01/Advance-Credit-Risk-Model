libname d '';

/***** Data Preparation *****/

data mortgage;
set d.mortgage2;
run;

proc means mean median mode std p1 p99 min max maxdec=4; 
var  mat_time balance_time LTV_time interest_rate_time balance_orig_time interest_rate_orig_time FICO_orig_time LTV_orig_time;
run;

data mortgage2;
set mortgage;
if balance_orig_time>0;
if balance_time > 975000 then balance_time = 975000;
if LTV_time > 137.568 then LTV_time = 137.568;
if interest_rate_time > 12 then interest_rate_time = 12;
if balance_orig_time > 1000000 then balance_orig_time = 1000000;
if LTV_orig_time > 100 then LTV_orig_time = 100;

run;

data d.mortgage2;
set mortgage2;
run;

ods graphics on;
proc univariate data=mortgage2;
	var mat_time balance_time LTV_time interest_rate_time balance_orig_time interest_rate_orig_time FICO_orig_time LTV_orig_time;
	histogram mat_time balance_time LTV_time interest_rate_time balance_orig_time interest_rate_orig_time FICO_orig_time LTV_orig_time;
run;
ods graphics off;

proc freq data=mortgage2;
	tables REtype_CO_orig_time;
	tables REtype_PU_orig_time;
	tables REtype_SF_orig_time;
	tables investor_orig_time;
run;


ods graphics on;
proc corr data=mortgage2;
plots(maxpoints=none)=scatter(nvar=2 alpha=0.20 0.30);
kendall spearman;
var mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time balance_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index vix_index cpi_index fed_funds_rate ism cpr;
run;;
ods graphics off;

libname data 'C:\Users\VoramatePasharawipas\Desktop\MSA-MRM GSU\Course\4-Fall 2019\Advance Credit Risk Model\Final Project\Data';
data mortgage2;
	set data.mortgage2;
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

proc plm source=model_cloglog;
	score data=test out=testcloglog;
run;

proc plm source=model_logistic;
	score data=test out=testlogistic;
run;

proc plm source=model_probit;
	score data=test out=testprobit;
run;

data Testlinear;
set Testlinear;
sqerror=(predicted-default_time)**2;
run;

data Testcloglog;
set Testcloglog;
pdcloglog=1-exp(-exp(predicted));
sqerror=(pdcloglog-default_time)**2;
run;

data Testlogistic;
set Testlogistic;
pdlogistic=1/(1+exp(-predicted));
sqerror=(pdlogistic-default_time)**2;
run;

data Testprobit;
set Testprobit;
pdprobit=probnorm(predicted);
sqerror=(pdprobit-default_time)**2;
run;



proc means data=Testlinear;
var predicted default_time sqerror;
run;

proc means data=Testprobit;
var pdprobit default_time sqerror;
run;

proc means data=Testcloglog;
var pdcloglog default_time sqerror;
run;

proc means data=Testlogistic;
var pdlogistic default_time sqerror;
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

proc means data=class;
var errprobit errlogistic errcloglog errpredicted;
run;


