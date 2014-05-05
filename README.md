ffmpegwriter
============

A Matlab tool for creating movies.

Installation
------------

  1. install ffmpeg
    * Windows: static build is available from  [ffmpeg.org](http://ffmpeg.org/download.html) (see windows builds)
    * OS X: install via [homebrew](http://brew.sh/) ("brew install ffmpeg")
    * Linux: most distribution provie a package for ffmpeg
  2. download or clone the ffmpegWriter repository
    * The content of the repository has to be in a folder which is in the PATH of Matlab.
    * In Matlab File->Set Path shows all folders in the PATH and also allows adding additional folder to the PATH.

Usage
-----

A small example should be sufficient to demonstrate how to use ffmpegWriter.
```matlab
fw = ffmpegWriter();                     % initialize ffmpegWriter
fw.ffmpeg = '/usr/local/bin/ffmpeg'      % set path to ffmpeg on OS X (if installed using homebrew)
% fw.ffmpeg = 'C:\ffmpeg\bin\ffmpeg.exe' % set path to ffmpeg on Windows 
%                                        %     (if installed to C:\ffmpeg\bin\)
%                                        % setting the path to ffmpeg is not necessary on Linux
x = [1:0.01:pi];
for k=1:20
    plot(x,sin(k*x)); 
    fw.getFrame();                       % append current figure as a frame to the video
end
fw.writeMovie('sin.mp4',5);              % create h264 encoded video with a
                                         % framerate of 5 frames/second and
                                         % write it to sin.mp4
% fw.writeMovie('sin.webm',5);           % create vp8/webm encoded video with a 
                                         % framerate of 5 frames/second and
                                         % write it to sin.webm
```

Some additional examples:
```matlab
fw = ffmpegWriter([640 480]);  % dimensions of the final video are set to 640 x 480
```

```matlab
fw.getFrame(h);                 % append current state of figure h to the video
```

For further information, have a look at the matlab help text supplied with ffmpegWriter (help ffmpegWriter).

Include video in LaTeX
----------------------

The videos created by ffmpegWriter can be included in LaTeX document with the help of the media9 package. 
```latex
\usepackage{media9}

...

\includemedia[
  activate=pageopen,        
  width=300pt,
  height=200pt,
  addresource=sin.mp4,      % path to video file
  flashvars={%
     src=sin.mp4            % use same path as for addresource!
  }  
]{}{StrobeMediaPlayback.swf}
```
