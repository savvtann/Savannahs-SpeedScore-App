using Toybox.Attention;
using Toybox.System;

class AudioHelper {
    
    function playScoreFeedback(strokes, par) {
        if (!(Attention has :playTone)) {
            return; // device doesn't support tones
        }

        var diff = strokes - par;

        if (diff <= -1) {  // Birdie or better
            Attention.playTone(Attention.TONE_SUCCESS);
            Attention.vibrate([ new Attention.VibeProfile(50, 50), new Attention.VibeProfile(0, 50), new Attention.VibeProfile(50, 50), new Attention.VibeProfile(0, 50), new Attention.VibeProfile(50, 50)  ]);
        } 
        else if (diff == 0) {  // Par
            Attention.playTone(Attention.TONE_LOUD_BEEP);
            Attention.vibrate([ new Attention.VibeProfile(50, 50), new Attention.VibeProfile(0, 50), new Attention.VibeProfile(50, 50)]);
        } 
        else if (diff == 1) {  // Bogey
            Attention.playTone(Attention.TONE_KEY);
            Attention.vibrate([ new Attention.VibeProfile(50, 200)]);
        } 
        else {  // Double bogey or worse
            Attention.playTone(Attention.TONE_FAILURE);
            Attention.vibrate([ new Attention.VibeProfile(50, 100)]);
        }
    }

    // Hole completed (regardless of score)
    function holeComplete() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_START);
        }
        // Optional: short vibration
        if (Attention has :vibrate) {
            Attention.vibrate([ new Attention.VibeProfile(50, 200) ]);
        }
    }

    // New round started
    function roundStarted() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
    }

    // Error or warning (e.g., invalid input)
    function warning() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ERROR);
        }
    }

    // Simple confirmation (e.g., score saved)
    function confirm() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_KEY);
        }
    }
    
    // Play a two-tone success
    function playChime() {
        if (Attention has :playTone) {
            // Quick success pattern
            Attention.playTone(Attention.TONE_START);  // High beep
            Attention.playTone(Attention.TONE_LOUD_BEEP);  // Followed by another
        }
    }
    
    // Play error sound
    function playError() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_FAILURE);  // Sad buzz
        }
    }
}