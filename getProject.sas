

%macro getProject(wordList);
	%global cpd prot dm_cpd dm_prot;

	/*Iterate through tokenized list returned from %words */
	%do i=1 %to &wordList;
		/*  When you get to the Projects folder, the next two
			the next two tokens are compound and project
			dm_ globals are for setting libnames for s:/stats/ DM area  */
		%if &&W&i=Projects %then
			%do;
				%let x = %eval(&i + 1);
				%let cpd = &&W&x;
				%put COMPOUND: &cpd;
				%let x = %eval(&i + 2);
				%let prot = &&W&x;
				%put PROJECT: &prot;
				%let dm_cpd = %substr(&prot,1,3)-%substr(&prot,4,2);
				%put DM PATH: &dm_cpd;
				%let dm_prot = %substr(&prot,1,3)-%substr(&prot,4,2)-%substr(&prot,6,3);
				%put DM PROTOCOL: &dm_prot;
			%end;
		%else %if &&W&i ~= Projects %then %do;
			%let cpd = ;
			%let prot = ;
			%let dm_cpd = ;
			%let dm_prot = ;
			%put WARNING: Unable to determine project path. Try executing the init macro from the project area ;
		%end;
	%end;
%mend;
