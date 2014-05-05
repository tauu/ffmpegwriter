classdef ffmpegWriter < handle
    %FFMPEGWRITER creates a h.264 encoded movie from a sequence of images using ffmpeg
    %   
    %   UASGE
    %   
    %   == example ==
    %
    %   fw = ffmpegWriter();                    % initialize ffmpegWriter
    %   x = [1:0.01:pi];
    %   for k=1:20
    %   	plot(x,sin(k*x)); 		
    %   	fw.getFrame();                  % use current plot as a frame in the video
    %   end
    %   fw.writeMovie('sin.mp4',5);             % create video with a framerate of 5 frame/second and write it to sin.mp4
    %
    %
    %   == additional information ==
    %   
    %   fw = ffmpegWriter([width height]);
    %
    %   [width,height] specifies the size of the video in pixels. The video
    %   will NOT be scaled to this size but the figures used to create it will
    %   be resized to this size before exporting them as images.
    %   If no video size is specified ffmpeg will just use whatever size the
    %   figure has when a frame is captured.
    %   All images created by fw will be removed if it is deleted.
    %
    %
    %   fw.getFrame(h);
    %   
    %   getFrame adds the current state of figure h to the video.
    %   If h is omitted it will use the current figure.
    %
    %
    %   fw.writeMovie(filename,fps)
    %   
    %   writeMovie creates video with a framerate of fps frames/second 
    %   containing all captured frames.
    %   The filename has to end with ".mp4".
    %   If no value for fps is specified it defaults to 30.
    %
    %   
    %   == Options ==
    %
    %   fw.ffmpeg = '/opt/local/bin/ffmpeg';    
    %
    %   ffmpeg sets the path to ffmpeg excetuable
    %
    %
    %   fw.keepImages = true
    %
    %   Images will not be removed if the ffmpegWriter object is deleted.
    %   The default behaviour is to removed them.
    %
    %
    %   fw.ffmpegOptions = ' -loglevel warning -y '
    %
    %   ffmpegOptions is a string of additional parameters that will be
    %   passed to ffmpeg. Its default value is given above.
    %   Please see http://ffmpeg.org/ffmpeg.html for a list of options.
    
    properties
	    ffmpeg = 'ffmpeg'; 			% path to the ffmpeg executable
	    keepImages = false; 		% whether to keep the temporary images after the video has been created
	    ffmpegOptions = [ ...		% additional parameters to pass to ffmpeg
		    ' -loglevel warning ' ... 	      % print only warnings and errors
		    ' -pix_fmt yuv420p ' ... 	      % the new default format is not yet supported by many video player
		    ' -y '];			      % overwrite output without asking
    end
    
    properties (SetAccess = protected, Hidden = true)
	    tmpDir; 				% directory in which the temporary images should be stored
	    tmpDirParent = 'ffmpegWriterTmp/';  % parent directory of tmpdir
	    index; 				% counter for the created images
	    resizeFigure; 			% should the figure be resized or its original size be sued ?
	    width; 				% width of the video
	    height; 				% height of the video
    end

    methods
	function fw = ffmpegWriter(vsize)
	    % create new temporary directory
	    fw.tmpDir = [ fw.tmpDirParent datestr(now,'yyyy-mm-dd--HH-MM-SS-FFF') '/'];
	    status = exist(fw.tmpDir,'dir');
	    if (~ status)
		status = mkdir([fw.tmpDir]);
	    end
	    if (~ status) 
		error(['could not create temporary directory "' fw.tmpDir '"']); 
	    end
	    % set size of video
	    if nargin > 0
		if( isvector(vsize) && length(vsize) == 2 )
		    fw.width = vsize(1);
		    fw.height = vsize(2);
		    fw.resizeFigure = true;
		else
		    error('video size has to be given in the following format [width height]');
		end
	    else
		fw.resizeFigure = false;
	    end
	    % index of first image
	    fw.index = 1;
	end

	% create a frame from the current figure
	function getFrame(this,h)
	    % if no handle is given, use gcf
	    if nargin > 1
		if ishandle(h)
		    cf = h;
		else
		    warning('first parameter is no valid handle, falling back to gcf');
		end
	    else
		cf = gcf;
	    end
	    filename = this.tempFilename(this.index);
	    if (this.resizeFigure) 
		% fix PaperPosition so that the printed image
		% will have the requested size 
		%
		% store current figure properties
		origPP = get(cf,'PaperPosition');
		origPU = get(cf,'PaperUnits');
		% change units to inches as this makes dpi calculations easier
		set(cf,'PaperUnits','inches');
		tempPP = get(cf,'PaperPosition');
		% calculate width and height of the figure on paper
		% so that if we print it with a resolution of 72dpi the image
		% will have the desired size
		newPP  = [tempPP(1:2) (this.width-1)/72 (this.height-1)/72];
		set(cf,'PaperPosition', newPP);
		% force drawing and print figure to a file
		drawnow;
		print(cf, '-dpng','-r72', filename);
		% reset figure properties to their original values
		set(cf,'PaperUnits', origPU);
		set(cf,'PaperPosition', origPP);
	    else
		% store current figure properties
		origPPM = get(gcf,'PaperPositionMode');
		set(gcf,'PaperPositionMode','auto');
		% force drawing and print figure to a file
		drawnow;
		print(cf, '-dpng','-r72', filename);
		% reset figure properties to their original values
		set(gcf,'PaperPositionMode',origPPM);
	    end
	    this.index = this.index + 1;
	end

	% convert the sequence of images into a movie
	function writeMovie(this,file,fps)
	    % check input
	    if nargin < 2
		error('You have to specify a filename for the video.')
	    end
	    [path,name,ext] = fileparts(file);
	    if (strcmpi(ext,'.mp4')) 
		vcodec = ' -vcodec libx264 ';
	    elseif (strcmpi(ext,'.webm'))
		vcodec = ' -vcodec libvpx ';
	    else
		error('The extension of the filename has to be ".mp4" or ".webm".');	
	    end
	    if nargin < 3
		    fps = 30;
	    end
	    % check if there are enough frames to create a video
	    if (this.index < 2)
		error('You have just tried to create a video with just one frame ... probably something went wrong. ;-) ');
	    end
	    % read size of images to determine the video size
	    % if the figures are not resized to a specified size
	    if ( ~ this.resizeFigure )
		fimage = tempFilename(this,1);
		info = imfinfo(fimage);
		this.width  = info.Width;
		this.height = info.Height;
	    end
	    % if eiter width or height is not even
	    % libx264 will throw an error so we will crop
	    % to an even size if the images do not have an even size
	    wcrop = mod(this.width,2);
	    hcrop = mod(this.height,2);
	    if (wcrop ~= 0 || hcrop ~= 0) 
		vcrop = sprintf('-vf crop=%d:%d:%d:%d',this.width,this.height,wcrop,hcrop);
		this.width = this.width - wcrop;
		this.height = this.height - hcrop;
	    else
		vcrop = '';
	    end
	    % create string for the video size setting
	    vsize = [num2str(this.width) ':' num2str(this.height)];
	    % disable coloring of output
	    setenv('NO_COLOR','1');              % deprecated - but still used
	    setenv('AV_LOG_FORCE_NOCOLOR','1');  % only used by really new ffmpeg versions
	    % run ffmpeg
	    system( [ this.ffmpeg ...
		    ' -f image2 ' ...                 % input = sequence of images
		    ' -r ' num2str(fps) ...           % frames per second in final video
		    ' -i ' this.tmpDir '%d.png ' ...  % pictures to use as input
		    vcodec ... 	       		      % video format (H.264 oder WebM)
		    vcrop ... 			      % crop video if necessary
		    ' -s ' vsize ... 		      % video size
		    this.ffmpegOptions ...	      % additional options
		    ' ' file]);
	end

	% deconstructor
	function delete(this)
	    if ( ~ this.keepImages )
		this.cleanup();
	    end
	end
    end

    methods (Access = protected) 
	% create temporary filename fot the i-th temporary file
	function filename = tempFilename(this,i)
	    filename = [this.tmpDir num2str(i) '.png'];
	end

	
	% remove all temporary images and its temporary folder
	function cleanup(this)
	    for i=1:this.index-1
		delete(this.tempFilename(i));
	    end
	    rmdir(this.tmpDir);
	    % also remove its parent directory if it is empty
	    status = rmdir(this.tmpDirParent);
	end
    end
end

