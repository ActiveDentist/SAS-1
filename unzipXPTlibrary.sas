libname outfile 'C:\Users\dpressley\Projects\implantable\XPT\datasets\';

*// create dataset which contains files in the XPT directory;
data yfiles;
	 keep filename ;
	 length fref $8 filename $80;
	 rc = filename(fref, 'C:\Users\dpressley\Projects\implantable\XPT\');
	 if rc = 0 then
	 do;
	 did = dopen(fref);
	 rc = filename(fref);
	 end;
	 else
	 do;
	 length msg $200.;
	 msg = sysmsg();
	 put msg=;
	 did = .;
	 end;
	 if did <= 0
	 then
	 putlog 'ERR' 'OR: Unable to open directory.';
	 dnum = dnum(did);
	 do i = 1 to dnum;
	 filename = dread(did, i);
	 /* If this entry is a file, then output. */
	 fid = mopen(did, filename);
	 if fid > 0
	 then
	 output;
	 end;
	 rc = dclose(did);
 run;
                                                             
*// create macro vars;
%let datasets=;
%let count=;
%let xpt = ;

*//select filenames for dynamic libname and select statements on copy procedure, count for iterating loop;
proc sql noprint;
	select filename2 into: datasets separated by ' '
	from yfiles;

	select count(*) into: count
	from yfiles;

	select filename into: xpt separated by ' '
	from yfiles;

quit;
%put &datasets;
%put &count;
%put &xpt;


*//do the magic;
%macro unzip();
%do i=1 %to %words(&xpt);
	%put %scan(&&w&i,1,'.');
	libname infile xport  "C:\Users\dpressley\Projects\implantable\XPT\&&w&i";

	proc copy in=infile out=outfile memtype=data;
		select %scan(&&w&i,1,'.');
	run;
%end;

%mend unzip;

%unzip;

