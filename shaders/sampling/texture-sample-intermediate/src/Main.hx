package;

import lime.utils.Assets;
import lime.graphics.Image;
import peote.view.Texture;
import haxe.CallStack;
import lime.app.Application;
import lime.ui.Window;
import peote.view.PeoteView;
import peote.view.Buffer;
import peote.view.Display;
import peote.view.Program;
import peote.view.Color;

class Main extends Application {
	var lightBuffer:Buffer<Sprite>;
	var light:Sprite;

	override function onPreloadComplete():Void {
		// access embeded assets from here
		switch (window.context.type) {
			case WEBGL, OPENGL, OPENGLES:
				try
					startSample(window)
				catch (_)
					trace(CallStack.toString(CallStack.exceptionStack()), _);
			default:
				throw("Sorry, only works with OpenGL.");
		}
	}

	// ------------------------------------------------------------
	// --------------- SAMPLE STARTS HERE -------------------------
	// ------------------------------------------------------------

	public function startSample(window:Window) {
		var peoteView = new PeoteView(window);

		// main display
		var display = new Display(0, 0, window.width, window.height, Color.CYAN);
		peoteView.addDisplay(display);

		// new display which will render to a texture
		var texture_display = new Display(0, 0, window.width, window.height);
		peoteView.addFramebufferDisplay(texture_display);
		
		// the texture which the display will render to
		var texture = new Texture(window.width, window.height);
		texture_display.setFramebuffer(texture, peoteView);

		// wabbit Pwogwam
		var spriteBuffer = new Buffer<Sprite>(100);
		var spriteProgram = new Program(spriteBuffer);
		display.addProgram(spriteProgram);

		// load wabbit texture and give to Program
		var wabbitImage = Assets.getImage("assets/wabbit_alpha.png");
		var spriteTexture = new Texture(wabbitImage.width, wabbitImage.height);
		spriteTexture.setImage(wabbitImage);
		spriteProgram.addTexture(spriteTexture, "wabbit");

		// init wabbit Sprite
		var wabbit = new Sprite(150, 150, wabbitImage.width, wabbitImage.height, 0xffffffff);
		spriteBuffer.addElement(wabbit);

		// lightProgram to draw on texture_display (and therefore the texture)
		lightBuffer = new Buffer<Sprite>(4, 4, true);
		var lightProgram = new Program(lightBuffer);
		lightProgram.alphaEnabled = true;

		// load a texture to be used for gradient light
		var lightImage = Assets.getImage("assets/gradient.png");
		var lightTexture = new Texture(lightImage.width, lightImage.height);
		lightTexture.setImage(lightImage);
		lightProgram.addTexture(lightTexture, "light");

		// add lightProgram to texture display
		texture_display.addProgram(lightProgram);

		// init the "light" sprite
		light = new Sprite(0, 0, 320, 320, 0xff0000ff);
		lightBuffer.addElement(light);

		// currently the darkness/light is not rendered because
		// the texture_display is not added to PeoteView
		// below we set up a new program that will render the texture which texture_display is producing

		// make new buffer and program to render the texture
		var renderBuffer = new Buffer<RenderElement>(1);
		var renderProgram = new Program(renderBuffer);

		// ! enable alpha (otherwise we can only handle 0.0 or 1.0 alpha, nothing in between)
		renderProgram.alphaEnabled = true;

		// add render program to main display
		display.addProgram(renderProgram);

		// add the texture to the program
		renderProgram.addTexture(texture, "sampledtexture");

		// inject glsl function which samples the color from "sampledtexture" at vTexCoord
		renderProgram.injectIntoFragmentShader("
		vec4 getColor(int sampledtexture) {
			
			// sample the texture
			vec4 textureSample = getTextureColor(sampledtexture, vTexCoord);

			// the two alpha levels we are working with
			float lightness_alpha = 1.0 - textureSample.a;
			float darkness_alpha = 0.8;

			// mix alpha level
			float alpha_blend = mix(lightness_alpha, darkness_alpha, 0.5) ;

			// return original sample color but use blended alpha 
			return vec4(textureSample.rgb, alpha_blend);

		}
		");

		// set program to use glsl function for the color
		renderProgram.setColorFormula('getColor(sampledtexture_ID)');

		// add new element to render buffer so that the render program has something to draw
		renderBuffer.addElement(new RenderElement(0, 0, window.width, window.height));
	}

	// ------------------------------------------------------------
	// ----------------- LIME EVENTS ------------------------------
	// ------------------------------------------------------------

	override function update(deltaTime:Int):Void {
		// for game-logic update
	}

	override function onMouseMove(x:Float, y:Float):Void {
		light.x = Std.int(x);
		light.y = Std.int(y);
		lightBuffer.updateElement(light);
	}

	// override function render(context:lime.graphics.RenderContext):Void {}
	// override function onRenderContextLost ():Void trace(" --- WARNING: LOST RENDERCONTEXT --- ");
	// override function onRenderContextRestored (context:lime.graphics.RenderContext):Void trace(" --- onRenderContextRestored --- ");
	// ----------------- MOUSE EVENTS ------------------------------
	// override function onMouseDown (x:Float, y:Float, button:lime.ui.MouseButton):Void {}
	// override function onMouseUp (x:Float, y:Float, button:lime.ui.MouseButton):Void {}
	// override function onMouseWheel (deltaX:Float, deltaY:Float, deltaMode:lime.ui.MouseWheelMode):Void {}
	// override function onMouseMoveRelative (x:Float, y:Float):Void {}
	// ----------------- TOUCH EVENTS ------------------------------
	// override function onTouchStart (touch:lime.ui.Touch):Void {}
	// override function onTouchMove (touch:lime.ui.Touch):Void	{}
	// override function onTouchEnd (touch:lime.ui.Touch):Void {}
	// ----------------- KEYBOARD EVENTS ---------------------------
	// override function onKeyDown (keyCode:lime.ui.KeyCode, modifier:lime.ui.KeyModifier):Void {}
	// override function onKeyUp (keyCode:lime.ui.KeyCode, modifier:lime.ui.KeyModifier):Void {}
	// -------------- other WINDOWS EVENTS ----------------------------
	// override function onWindowResize (width:Int, height:Int):Void { trace("onWindowResize", width, height); }
	// override function onWindowLeave():Void { trace("onWindowLeave"); }
	// override function onWindowActivate():Void { trace("onWindowActivate"); }
	// override function onWindowClose():Void { trace("onWindowClose"); }
	// override function onWindowDeactivate():Void { trace("onWindowDeactivate"); }
	// override function onWindowDropFile(file:String):Void { trace("onWindowDropFile"); }
	// override function onWindowEnter():Void { trace("onWindowEnter"); }
	// override function onWindowExpose():Void { trace("onWindowExpose"); }
	// override function onWindowFocusIn():Void { trace("onWindowFocusIn"); }
	// override function onWindowFocusOut():Void { trace("onWindowFocusOut"); }
	// override function onWindowFullscreen():Void { trace("onWindowFullscreen"); }
	// override function onWindowMove(x:Float, y:Float):Void { trace("onWindowMove"); }
	// override function onWindowMinimize():Void { trace("onWindowMinimize"); }
	// override function onWindowRestore():Void { trace("onWindowRestore"); }
}