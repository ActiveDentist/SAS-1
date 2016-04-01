%macro SET_OPTIONS ;

options nodate
        nonumber
		nofmterr
		mergenoby=WARN
		linesize=132
		pagesize=60
		missing=" "
		/*
		  Default text:
          formchar="|----|+|---+=|-/\<>*"
		  Default hex-representation:
		  formchar='7C2D2D2D2D7C2B7C2D2D2D2B3D7C2D2F5C3C3E2A'x
		  Solid vertical and horizontal bars in Courier only:
		  formchar='BD97979797BD97BD9797972B3D7C2D2F5CABBB2A'x
        */
		%if &UTSYSJOBINFO = INTERACTIVE %then %do ;
		  formchar="‚ƒ„…†‡ˆ‰Š‹Œ+=|-/\<>*"
		%end ;
		%else %do ;
		  formchar='BD97E0E1E2E3E4E5E6E7E82BE97C2D2F5CABBB2A'x
		%end ;
        
		fmtsearch=(utilfmt)
		;

%mend SET_OPTIONS ;