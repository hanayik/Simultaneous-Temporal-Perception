function gaborTest
close all;
%Clear the workspace and the screen
sca;
PsychDefaultSetup(2);
screenNumber = max(Screen('Screens'));
white = WhiteIndex(screenNumber);
grey = white / 2;
grn  = [0 0.8 0];
Screen('Preference', 'SkipSyncTests', 2);
bkoff = [repmat(grey,1,3) 1];
bkoff = [0.5 0.5 0.5 1];
[win, windowRect] = PsychImaging('OpenWindow', screenNumber, bkoff, [], 32, 2,...
    [], [],  kPsychNeed32BPCFloat);
Screen('BlendFunction', win, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');
gaborDimPix = 400;
sigma = gaborDimPix / 7;
orientation = 90;
contrast = 0.8;
aspectRatio = 1;
phase1 = 0;
phase2 = 0;

numCycles = 5;
freq = numCycles / gaborDimPix;

bkoff = [1 0.1 0 0];
backgroundOffset = [0 1 0 0];
disableNorm = 1;
preContrastMultiplier = 0.5;
gabortex = CreateProceduralGabor(win, gaborDimPix, gaborDimPix, [],...
    backgroundOffset, disableNorm, preContrastMultiplier, 1);

dstRect1 = CenterRectOnPoint([0 0 gaborDimPix gaborDimPix], windowRect(4)*0.2, windowRect(3)*0.5);
dstRect2 = CenterRectOnPoint([0 0 gaborDimPix gaborDimPix], windowRect(4)*0.8, windowRect(3)*0.5);
colorToModulateBy = [1 0 0 0];
ifi = Screen('GetFlipInterval', win);
waitframes = 1;
nframes = 30;
b1 = 0.3;
b2 = 0.5;
colortoplot = [];
easeGain = 0.8; %gain for easing function
%val1 = sin(((pi/2).*(0:nframes/2))/(nframes/2)); % equation that alex found!
%val2 = asin((pi/2).*(0:nframes/2)/(nframes/2));
%val = [val1 val2];
for i = 1:3
    vbl = Screen('Flip', win);
    for f = 1:nframes
%         a = (f*2)/nframes;
%         if f < nframes/2
%             bias1 = a^(2+b1);
%             bias2 = a^(2+b2);
%         else
%             bias1 = 1-(a-1)^(2+b1);
%             bias2 = 1-(a-1)^(2+b2);
%         end
        %a = (f*2)/nframes;
        nfdiv2 = nframes/2;
        
        if f <= nfdiv2
            bias1 = getBias(f/(nfdiv2),b1);
            bias2 = getBias(f/(nfdiv2),b2);
        else
            bias1 = 1 - getBias((f - ceil(nfdiv2) )/(nfdiv2),b1);
            bias2 = 1 - getBias((f - ceil(nfdiv2) )/(nfdiv2),b2);
            
        end

        
        %allvals(f) = val;
        allvals(1,f) = bias1;
        allvals(2,f) = bias2;

%         g1 = getGain(f/(nframes+1), bias1);
%         g2 = getGain(f/(nframes+1), bias2);
%         bias1 = bias1 * g1;
%         bias2 = bias2 * g2;

        bias1toplot(f) = bias1;
        bias2toplot(f) = bias2;
        %clr1 = (backgroundOffset*(1-bias1))+ (colorToModulateBy*bias1);
        %clr1 = [0.5 0.5 0.5 0];
        %clr2 = (backgroundOffset*(1-bias1))+ (colorToModulateBy*bias2);
         %clr1 = [0.5 0.5 0.5 0] * bias1;
        clr1 = (colorToModulateBy*bias1);
        clr2 = (colorToModulateBy*bias2);
        colortoplot(f,:)= clr2;
        %fprintf('%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\n', g, bias1, bias2,clr1(1), clr1(2), clr1(3), clr2(1), clr2(2), clr2(3));
        propertiesMat1 = [phase1, freq, sigma, contrast, aspectRatio, 0, 0, 0];
        propertiesMat2 = [phase2, freq, sigma, contrast, aspectRatio, 0, 0, 0];
        Screen('DrawTextures', win, gabortex, [], dstRect1, orientation, [], [], clr1(1:end-1), [],...
            kPsychDontDoRotation, propertiesMat1');
        Screen('DrawTextures', win, gabortex, [], dstRect2, 70, [], [], clr2(1:end-1), [],...
            kPsychDontDoRotation, propertiesMat2');
        
        vbl  = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);
        if f == 1 
            KbWait(-1);
        end
    end
    Screen('Flip', win);
    %WaitSecs(1);
    save_to_base(1);
end

% Wait for a button press to exit
%KbWait(-1);


% Clear screen
sca;
close all;
plot(bias1toplot, 'r');
hold on;
plot(bias2toplot, 'b');
line([((nframes+1)/2) ((nframes+1)/2)],[0 1]);
xlim([1 nframes]);
ylim([0 1]);


end

function bias = getBias(t, b)
%credit: http://demofox.org/biasgain.html
    %if (b <= 0) | (t <= 0), bias = 0; return; end; %#ok
    %if (b >= 1) | (t >= 1), bias = 1; return; end; %#ok
    bias = (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
   % (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
    
end

function gn = getGain(t, g)
%credit: http://demofox.org/biasgain.html
 if(t < 0.5)
    gn = getBias(t * 2.0,g)/2.0;
  else
    gn = getBias(t * 2.0 - 1.0,1.0 - g)/2.0 + 0.5;
 end
end