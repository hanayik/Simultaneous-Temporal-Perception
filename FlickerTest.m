function [redColor, grnColor, gryColor] = FlickerTest(params)
%typical PTB setup routines
%PsychDefaultSetup_dev(3);
%params = PsychSetupParams(1,1);
KbName('UnifyKeyNames');
%set default color values
grnColor = [0 0.7 0]';
redColor = [0.8 0 0]';
gryColor = [0.7 0.7 0.7]';
%while loop for flicker screen
while 1
    %set Green and Red rectangles opposite of each other
    grnRect = [0 0 params.maxXpixels/2 params.maxYpixels/2; params.maxXpixels/2 params.maxYpixels/2  params.maxXpixels params.maxYpixels]';
    redRect = [params.maxXpixels/2 0 params.maxXpixels params.maxYpixels/2; 0 params.maxYpixels/2 params.maxXpixels/2 params.maxYpixels]';
    
    %Fill them with color and show on screen
    Screen('FillRect',params.win,[grnColor grnColor redColor redColor],[grnRect redRect]);
    Screen('DrawDots', params.win, [params.Xc params.Yc], 15 ,params.colors.black, [], 2);
    Screen('Flip',params.win);
    Screen('FillRect',params.win,[redColor redColor grnColor grnColor],[grnRect redRect]);
    Screen('Flip',params.win);
    
    [keyIsDown, secs, keycode] = KbCheck(-1);
    if keycode(KbName('2@'))
        grnColor(2) = grnColor(2)-0.01;
    elseif keycode(KbName('3#'))
        grnColor(2) = grnColor(2)+0.01;
    elseif keycode(KbName('4$'))
        WaitSecs(2);
        break;
    end
end
WaitSecs(2);%2sec pause between flicker types
%while loop for gray and red flicker screen
while 1
    %set Gray and Red rectangles opposite of each other
    gryRect = [0 0 params.maxXpixels/2 params.maxYpixels/2; params.maxXpixels/2 params.maxYpixels/2  params.maxXpixels params.maxYpixels]';
    redRect = [params.maxXpixels/2 0 params.maxXpixels params.maxYpixels/2; 0 params.maxYpixels/2 params.maxXpixels/2 params.maxYpixels]';
    
    %Fill them with color and show on screen
    Screen('FillRect',params.win,[gryColor gryColor redColor redColor],[gryRect redRect]);
    Screen('DrawDots', params.win, [params.Xc params.Yc], 15 ,params.colors.black, [], 2);
    Screen('Flip',params.win);
    Screen('FillRect',params.win,[redColor redColor gryColor gryColor],[gryRect redRect]);
    Screen('Flip',params.win);
    [keyIsDown, secs, keycode] = KbCheck(-1);
    if keycode(KbName('2@'))
        gryColor(:) = gryColor(:)-0.01;
    elseif keycode(KbName('3#'))
        gryColor(:) = gryColor(:)+0.01;
    elseif keycode(KbName('4$'))
        WaitSecs(2);
        break;
    end
end