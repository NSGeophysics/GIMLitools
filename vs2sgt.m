function vs2sgt(infiles,source_elevs,geoph_elevs,outfile)
  %% vs2sgt(infiles,elevations)
  %%
  %% Turns the list of PickWin .vs files infiles
  %% into a GIMLi readable .sgt file
  %%
  %% INPUT:
  %%
  %% infiles        Filenames of the picked files
  %%                {'firstshot.vs','secondshot.vs',...}
  %%
  %% source_elevs   vector containing the profile position
  %%                of each source (first column) and the elevations
  %%                (second column)
  %%
  %% geoph_elevs    If all infiles have the same geophones:
  %%                   Nx1 vector containing the elevations of the geophones
  %%
  %% outfile        name for outfile. Don't append the .sgt
  %%
  %%
  %% EXAMPLE:
  %%
  %% vs2sgt({'shot1.vs','shot2.vs'},[0,0],zeros(24,1),'shots');
  %% % Then invert the resulting file shots.sgt using GIMLi
  %% %(see https://github.com/gimli-org/gimli/blob/master/examples/
  %% %traveltime/example.py)
  %%
  %% COMMENT:
  %% 
  %% You can create an .sgt file assuming each input file has an independent
  %% set of geophones by setting geoph_elevs to the Nxlength(infiles) matrix
  %% containing the elevations for each set of geophones for each input file.
  %%                   
  %% Last modified by plattner-at-ethz.ch, 11/15/2017

  %% First reading all the files
  x_source=nan(length(infiles),1);
  n_geoph=nan(length(infiles),1);
  source_elevs=source_elevs(:);
  
  for i=1:length(infiles)
    %% Read in each line
    fid=fopen(infiles{i},'r');
    %% First line: Year and some stuff. unimportant
    line=fgetl(fid);
    %% second line: geophone spacing and stuff... not important
    line=fgetl(fid);
    %% third line: shot location, number of geophones (= number of measurements)
    line=fgetl(fid);
    ln=sscanf(line,'%f %d %f');
    x_source(i)=ln(1);
    n_geoph(i)=ln(2);
    
    x_geoph{i}=nan(n_geoph(i),1);
    tt{i}=nan(n_geoph(i),1);
    %% then read the next 24 lines: profile position, travel time, 1
    for j=1:n_geoph(i)
      line=fgetl(fid);
      ln=sscanf(line,'%f %f %d');
      x_geoph{i}(j)=ln(1);
      %% Travel time is given in milliseconds
      tt{i}(j)=ln(2)/1000;
    end

    fclose(fid);
  end
    
  %% Strategy: First put all the geophones,
  %% then all the sources, then sort. Build data using
  %% vector that tells us where theindividual positions will go
  %% Need to do sorting twice for that.


  
  if size(geoph_elevs,2)==1
    pos=[x_geoph{i}(:) geoph_elevs(:);x_source source_elevs];
    %% Sort the positions
    [pos,indf]=sortrows(pos,1);
    %% Want to know where the positions will go
    [~,ind_sort]=sort(indf);
    %% the ind_sort vector tells us where the individual
    %% elements go when we sort pos
    
    data=nan(length(infiles)*n_geoph(1),3);
    for i=1:length(infiles)
      data((i-1)*n_geoph(1)+1:i*n_geoph(1),:)=...
      [ind_sort((n_geoph(1)+i)*ones(n_geoph(1),1)),...
       ind_sort((1:n_geoph(1))'),tt{i}];
    end
  end

  %% In case each set of geophones is different
  if size(geoph_elevs,2)==length(infiles)
    x_geoph_total=nan(sum(n_geoph),1);
    x_geoph_total(1:n_geoph(1))=x_geoph{1};
    for i=2:length(infiles)
      x_geoph_total(sum(n_geoph(1:i-1))+1:sum(n_geoph(1:i)))=x_geoph{i};
    end
    %% Add the sources at the end
    pos=[x_geoph_total geoph_elevs(:);x_source source_elevs];
    %% Now create vector that will tell us where the elements
    %% go when we sort
    %% Sort the positions
    [pos,indf]=sortrows(pos,1);
    %% Want to know where the positions will go
    [~,ind_sort]=sort(indf);
    %% the ind_sort vector tells us where the individual
    %% elements go when we sort pos
    %% Use this to build data
    data=nan(sum(n_geoph),3);
    %% First geophone usorted index
    firstg=sum(n_geoph)+1;
    data(1:n_geoph(1),:)=[ind_sort(firstg*ones(n_geoph(1),1)),...
			  ind_sort((1:n_geoph(1))'),tt{1}];
    for i=2:length(infiles)
      data(sum(n_geoph(1:i-1))+1:sum(n_geoph(1:i)),:)=...
      [ind_sort((firstg+i-1)*ones(n_geoph(i),1)),...
       ind_sort((sum(n_geoph(1:i-1))+1:sum(n_geoph(1:i)))'),tt{i}];
    end   
  end

  fid=fopen([outfile '.sgt'],'w');

  fprintf(fid,'%d # shot/geophone points\n',size(pos,1));
  fprintf(fid,'#x \t y\n');
  for i=1:size(pos,1)
    fprintf(fid,'%g \t %g\n',pos(i,1),pos(i,2));
  end
  fprintf(fid,'%d # measurements\n',size(data,1));
  fprintf(fid,'#s \t g \t t\n');
  for i=1:size(data,1)
    fprintf(fid,'%d \t %d \t %g\n',data(i,1),data(i,2),data(i,3));
  end

  fclose(fid);
  
  
  end
