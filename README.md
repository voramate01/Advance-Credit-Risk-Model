# Advance-Credit-Risk-Model
* Objective: Estimate the expected loss on a pool of mortgages. The loss model is built with three risk parameters: Probability of Default (PD)
, Loss Given Default (LGD) and Exposure at Default (EAD)


* To help illustrate the methodology, the following variables are defined</br>
𝐿(𝑖,𝑡) : the loss amount given default on mortgage i at time t </br>
𝐸[𝐿𝑡] : the total expected loss amount at time t

Based on A-IRB, the loss given default on mortgages are estimated by</br>
𝐸[𝐿𝑖,𝑡]=𝑃𝐷(𝑖,𝑡)∗𝐸𝐴𝐷(𝑖,𝑡)∗𝐿𝐺𝐷(𝑖,𝑡)</br>
𝑃𝐷𝑖,𝑡: the probability that mortgage I defaults over one-year period at time t (0-100%)</br>
𝐸𝐴𝐷𝑖,𝑡: the monetary exposure at default of mortgage I at time t</br>
𝐿𝐺𝐷𝑖,𝑡: the estimated economic loss given default of mortgage I at time t as a percentage of exposure (0-100%)
PD, EAD and LGD, are modeled
