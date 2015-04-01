%macro sitepain_opioid(prot=) ;
%local i ;

%* list all drugs that qualify ;
(
  (
  %do i = 1 %to 9 ;
    index(atc&i.lev4,'OPIUM') |
    atc&i.lev3='OPIOIDS' |
  %end ;
  index(atcalev4,'OPIUM') |
  atcalev3='OPIOIDS' |
  drugterm in("VICODIN") |
  med in(
         "EFFERALGAN + CODEINE",
		 "EFFERALGAN CODEINE",
		 "OXYCODONE PAPACETAMOL",
		 "OXYCODONE PARACETAMOL",
		 "FIORICET W/CODEINE"
        )
  )
)

%* list other criteria ;
%if &prot=06 %then %do ;
  & aetreat='Y'
%end ;

%* list exclusions ;
& ~(

(0)
%if &prot=06 %then %do ;
| (patnum='0302010')
| (patnum='0302013')
| (patnum='0402017' & med in('ROBITUSSIN WITH CODEINE'))
| (patnum='0603605')
| (patnum='0404018' & med in('ROBITUSSIN DM'))
| (patnum='0407003')
| (patnum='0407005')
| (patnum='0407006')
| (patnum='0608601' & med in('PERCOCET'))
| (patnum='0608603')
| (patnum='0409002')
| (patnum='0409011')
| (patnum='0410006')
| (patnum='0410011')
| (patnum='0510501' & med in('PHENERGAN WITH CODEINE COUGH SYRUP'))
| (patnum='0415001')
| (patnum='0415008')
| (patnum='0418001')
| (patnum='0519503')
| (patnum='0619609' & med in('DARVOCET','PERCOCET'))
| (patnum='0420005')
| (patnum='0423001' & med in('CODEINE SYRUP'))
| (patnum='0524503')
| (patnum='0624602' & med in('FENTANYL'))
| (patnum='0550002')
| (patnum='0550008')
| (patnum='0550013' & med in('MORPHINE'))
| (patnum='0650604')
| (patnum='0552002' & med in('DAFALGAN CODEINE'))
| (patnum='0553001')
| (patnum='0553004')
| (patnum='0553008' & med in('CONTRAMAL'))
| (patnum='0554002' & med in('CODEIN SYRUP'))
| (patnum='0557002')
| (patnum='0557003')
| (patnum='0560002')
| (patnum='0561003')
| (patnum='0561007')
| (patnum='0565005' & med in('MORPHINE SULPHATE','ORAMORPH SUSPENSION 10MG/5ML'))
| (patnum='0665605')
| (patnum='0566004')
| (patnum='0666601' & med in('DIHYDROCODIENE'))
%end ;

)

%mend ;