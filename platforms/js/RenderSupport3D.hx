import js.Browser;

import js.three.Scene;
import js.three.Fog;

import js.three.Color;
import js.three.Vector2;
import js.three.Vector3;

import js.three.Object3D;
import js.three.Mesh;
import js.three.AxisHelper;
import js.three.GridHelper;
import js.three.TransformControls;

import js.three.Camera;
import js.three.PerspectiveCamera;

import js.three.Geometry;
import js.three.BoxGeometry;
import js.three.CircleGeometry;
import js.three.ConeGeometry;
import js.three.CylinderGeometry;

import js.three.Material;
import js.three.MeshBasicMaterial;

import js.three.Light;
import js.three.PointLight;

import js.three.Raycaster;

import js.three.TextureLoader;
import js.three.ObjectLoader;

import js.three.AnimationClip;
import js.three.AnimationMixer;
import js.three.Clock;

using DisplayObjectHelper;
using Object3DHelper;

class RenderSupport3D {
	public static function load3DLibraries(cb : Void -> Void) : Void {
		if (untyped __js__("typeof THREE === 'undefined'")) {
			var head = Browser.document.getElementsByTagName('head')[0];
			var jscounter = 0;
			var onloadFn = function() {
				jscounter++;

				if (jscounter > 2) {
					cb();
				}
			}

			var node = Browser.document.createElement('script');
			node.setAttribute("type","text/javascript");
			node.setAttribute("src", 'js/threejs/three.min.js');
			node.onload = function() {
				var node = Browser.document.createElement('script');
				node.setAttribute("type","text/javascript");
				node.setAttribute("src", 'js/threejs/MTLLoader.js');
				node.onload = onloadFn;
				head.appendChild(node);

				node = Browser.document.createElement('script');
				node.setAttribute("type","text/javascript");
				node.setAttribute("src", 'js/threejs/OBJLoader.js');
				node.onload = onloadFn;
				head.appendChild(node);

				node = Browser.document.createElement('script');
				node.setAttribute("type","text/javascript");
				node.setAttribute("src", 'js/threejs/GLTFLoader.js');
				node.onload = onloadFn;
				head.appendChild(node);
			};
			head.appendChild(node);
		} else {
			cb();
		}
	}

	public static function add3DChild(parent : Object3D, child : Object3D) : Void {
		parent.add3DChild(child);
	}

	public static function remove3DChild(parent : Object3D, child : Object3D) : Void {
		parent.remove3DChild(child);
	}

	public static function get3DObjectChildren(object : Object3D) : Array<Object3D> {
		return object.children;
	}

	public static function get3DObjectJSON(object : Object3D) : String {
		return haxe.Json.stringify(object.toJSON());
	}

	public static function make3DObjectFromJSON(json : Dynamic) : Object3D {
		json = haxe.Json.parse(json);
		return new ObjectLoader().parse(json);
	}

	public static function make3DGeometryFromJSON(json : Dynamic) : Object3D {
		json = haxe.Json.parse(json);
		var geometry : Object3D = untyped __js__("new THREE.ObjectLoader().parseGeometries(json)");

		if (haxe.Json.stringify(geometry) == "{}") {
			return untyped __js__("new THREE.ObjectLoader().parse(json).geometry");
		} else {
			return geometry;
		}
	}

	public static function make3DMaterialsFromJSON(json : Dynamic) : Object3D {
		json = haxe.Json.parse(json);
		var materials : Object3D = untyped __js__("new THREE.ObjectLoader().parseMaterials(json)");

		if (haxe.Json.stringify(materials) == "{}") {
			return untyped __js__("new THREE.ObjectLoader().parse(json).material");
		} else {
			return materials;
		}
	}

	public static function make3DStage(width : Float, height : Float) : ThreeJSStage {
		return new ThreeJSStage(width, height);
	}

	public static function make3DScene() : Scene {
		return new Scene();
	}

	public static function make3DColor(color : String) : Color {
		return new Color(color);
	}

	public static function set3DSceneBackground(scene : Scene, background : Dynamic) : Void {
		scene.background = background;
		scene.invalidateStage();
	}

	public static function set3DSceneFog(scene : Scene, fog : Fog) : Void {
		scene.fog = fog;
		scene.invalidateStage();
	}


	public static function load3DObject(objUrl : String, mtlUrl : String, onLoad : Dynamic -> Void) : Void {
		untyped __js__("
			new THREE.MTLLoader()
				.load(mtlUrl, function (materials) {
					materials.preload();

					new THREE.OBJLoader()
						.setMaterials(materials)
						.load(objUrl, onLoad);
				});
		");
	}

	public static function load3DGLTFObject(url : String, onLoad : Array<Dynamic> -> Dynamic -> Array<Dynamic> -> Array<Dynamic> -> Dynamic -> Void) : Void {
		untyped __js__("
			new THREE.GLTFLoader()
				.load(url, function (gltf) {
					onLoad(
						gltf.animations, // Array<THREE.AnimationClip>
						gltf.scene, // THREE.Scene
						gltf.scenes, // Array<THREE.Scene>
						gltf.cameras, // Array<THREE.Camera>
						gltf.asset // Object
					);
				});
		");
	}

	public static function load3DScene(url : String, onLoad : Dynamic -> Void) : Void {
		new ObjectLoader().load(url, onLoad);
	}

	public static function load3DTexture(object : Material, url : String) : Material {
		untyped object.map = new TextureLoader().load(url, untyped RenderSupportJSPixi.InvalidateStage);
		return object;
	}

	public static function make3DAxesHelper(size : Float) : Object3D {
		return new AxisHelper(size);
	}

	public static function make3DGridHelper(size : Float, divisions : Int, colorCenterLine : Int, colorGrid : Int) : Object3D {
		return new GridHelper(size, divisions, new Color(colorCenterLine), new Color(colorGrid));
	}


	public static function set3DCamera(stage : ThreeJSStage, camera : Camera) : Void {
		stage.camera = camera;
		stage.invalidateStage();
	}

	public static function set3DScene(stage : ThreeJSStage, scene : Scene) : Void {
		stage.scene = scene;

		// Chrome Inspect Three.js extension support
		untyped __js__("window.scene = scene;");

		stage.invalidateStage();
	}


	static function add3DEventListener(object : Object3D, event : String, cb : Void -> Void) : Void -> Void {
		object.addEventListener(event, untyped cb);

		return function() {
			object.removeEventListener(event, untyped cb);
		};
	}

	static function emit3DMouseEvent(object : Object3D, camera : Camera, event : String, x : Float, y : Float, ?handledObjects : Array<Dynamic>) : Void {
		if (handledObjects == null) {
			handledObjects = new Array<Dynamic>();
		}

		var raycaster = new Raycaster();
		raycaster.setFromCamera(new Vector2(x, y), camera);

		for (ob in raycaster.intersectObjects(object.children)) {
			var object = ob.object;

			if (handledObjects.indexOf(object) == -1) {
				handledObjects.push(object);
				object.emitEvent(event);
			}
		};

		for (child in object.children) {
			emit3DMouseEvent(child, camera, event, x, y, handledObjects);
		};
	}

	public static function add3DTransformControls(object : Object3D) : Object3D {
		return object;
	}

	public static function get3DObjectX(object : Object3D) : Float {
		return object.position.x;
	}

	public static function get3DObjectY(object : Object3D) : Float {
		return object.position.y;
	}

	public static function get3DObjectZ(object : Object3D) : Float {
		return object.position.z;
	}

	public static function set3DObjectX(object : Object3D, x : Float) : Void {
		if (object.position.x != x) {
			object.position.x = x;

			object.broadcastEvent("position");

			object.invalidateStage();
		}
	}

	public static function set3DObjectY(object : Object3D, y : Float) : Void {
		if (object.position.y != y) {
			object.position.y = y;

			object.broadcastEvent("position");

			object.invalidateStage();
		}
	}

	public static function set3DObjectZ(object : Object3D, z : Float) : Void {
		if (object.position.z != z) {
			object.position.z = z;

			object.broadcastEvent("position");

			object.invalidateStage();
		}
	}



	public static function get3DObjectRotationX(object : Object3D) : Float {
		return object.rotation.x / 0.0174532925 /*degrees*/;
	}

	public static function get3DObjectRotationY(object : Object3D) : Float {
		return object.rotation.y / 0.0174532925 /*degrees*/;
	}

	public static function get3DObjectRotationZ(object : Object3D) : Float {
		return object.rotation.z / 0.0174532925 /*degrees*/;
	}

	public static function set3DObjectRotationX(object : Object3D, x : Float) : Void {
		x = x * 0.0174532925 /*radians*/;

		if (object.rotation.x != x) {
			object.rotation.x = x;

			object.broadcastEvent("position");
			object.broadcastEvent("rotation");

			object.invalidateStage();
		}
	}

	public static function set3DObjectRotationY(object : Object3D, y : Float) : Void {
		y = y * 0.0174532925 /*radians*/;

		if (object.rotation.y != y) {
			object.rotation.y = y;

			object.broadcastEvent("position");
			object.broadcastEvent("rotation");

			object.invalidateStage();
		}
	}

	public static function set3DObjectRotationZ(object : Object3D, z : Float) : Void {
		z = z * 0.0174532925 /*radians*/;

		if (object.rotation.z != z) {
			object.rotation.z = z;

			object.broadcastEvent("position");
			object.broadcastEvent("rotation");

			object.invalidateStage();
		}
	}



	public static function get3DObjectScaleX(object : Object3D) : Float {
		return object.scale.x;
	}

	public static function get3DObjectScaleY(object : Object3D) : Float {
		return object.scale.y;
	}

	public static function get3DObjectScaleZ(object : Object3D) : Float {
		return object.scale.z;
	}

	public static function set3DObjectScaleX(object : Object3D, x : Float) : Void {
		if (object.scale.x != x) {
			object.scale.x = x;

			object.broadcastEvent("position");
			object.broadcastEvent("scale");

			object.invalidateStage();
		}
	}

	public static function set3DObjectScaleY(object : Object3D, y : Float) : Void {
		if (object.scale.y != y) {
			object.scale.y = y;

			object.broadcastEvent("position");
			object.broadcastEvent("scale");

			object.invalidateStage();
		}
	}

	public static function set3DObjectScaleZ(object : Object3D, z : Float) : Void {
		if (object.scale.z != z) {
			object.scale.z = z;

			object.broadcastEvent("position");
			object.broadcastEvent("scale");

			object.invalidateStage();
		}
	}

	public static function set3DObjectLookAt(object : Object3D, x : Float, y : Float, z : Float) : Void {
		object.lookAt(new Vector3(x, y, z));
		object.invalidateStage();
	}


	public static function get3DObjectBoundingBox(object : Object3D) : Array<Array<Float>> {
		var box = object.getBoundingBox();
		return [[box.min.x, box.min.y, box.min.z], [box.max.x, box.max.y, box.max.z]];
	}

	public static function add3DObjectPositionListener(object : Object3D, cb : Float -> Float -> Float -> Void) : Void -> Void {
		var fn = function(e : Dynamic) {
			cb(get3DObjectX(object), get3DObjectY(object), get3DObjectZ(object));
		};

		fn(0);

		object.addEventListener("position", fn);
		return function() { object.removeEventListener("position", fn); };
	}

	public static function add3DObjectRotationListener(object : Object3D, cb : Float -> Float -> Float -> Void) : Void -> Void {
		var fn = function(e : Dynamic) {
			cb(get3DObjectRotationX(object), get3DObjectRotationY(object), get3DObjectRotationZ(object));
		};

		fn(0);

		object.addEventListener("rotation", fn);
		return function() { object.removeEventListener("rotation", fn); };
	}

	public static function add3DObjectScaleListener(object : Object3D, cb : Float -> Float -> Float -> Void) : Void -> Void {
		var fn = function(e : Dynamic) {
			cb(get3DObjectScaleX(object), get3DObjectScaleY(object), get3DObjectScaleZ(object));
		};

		fn(0);

		object.addEventListener("scale", fn);
		return function() { object.removeEventListener("scale", fn); };
	}

	public static function add3DObjectBoundingBoxListener(object : Object3D, cb : (Array<Array<Float>>) -> Void) : Void -> Void {
		var fn = function(e : Dynamic) {
			cb(get3DObjectBoundingBox(object));
		};

		fn(0);

		object.addEventListener("box", fn);
		return function() { object.removeEventListener("box", fn); };
	}



	public static function make3DPerspectiveCamera(fov : Float, aspect : Float, near : Float, far : Float) : PerspectiveCamera {
		return new PerspectiveCamera(fov, aspect, near, far);
	}

	public static function set3DCameraFov(camera : PerspectiveCamera, fov : Float) : Void {
		camera.fov = fov;
	}

	public static function set3DCameraAspect(camera : PerspectiveCamera, aspect : Float) : Void {
		camera.aspect = aspect;
	}

	public static function set3DCameraNear(camera : PerspectiveCamera, near : Float) : Void {
		camera.near = near;
	}

	public static function set3DCameraFar(camera : PerspectiveCamera, far : Float) : Void {
		camera.far = far;
	}

	public static function get3DCameraFov(camera : PerspectiveCamera) : Float {
		return camera.fov;
	}

	public static function get3DCameraAspect(camera : PerspectiveCamera) : Float {
		return camera.aspect;
	}

	public static function get3DCameraNear(camera : PerspectiveCamera) : Float {
		return camera.near;
	}

	public static function get3DCameraFar(camera : PerspectiveCamera) : Float {
		return camera.far;
	}



	public static function make3DPointLight(color : Int, intensity : Float, distance : Float, decay : Float) : Light {
		return new PointLight(color, intensity, distance, decay);
	}

	public static function set3DLightColor(object : Light, color : Int) : Void {
		object.color = new Color(color);
		object.invalidateStage();
	}

	public static function set3DLightIntensity(object : Light, intensity : Float) : Void {
		object.intensity = intensity;
		object.invalidateStage();
	}

	public static function set3DLightDistance(object : PointLight, distance : Float) : Void {
		object.distance = distance;
		object.invalidateStage();
	}

	public static function set3DLightDecay(object : PointLight, decay : Float) : Void {
		object.decay = decay;
		object.invalidateStage();
	}

	public static function get3DLightColor(object : Light) : Int {
		return object.color.getHex();
	}

	public static function get3DLightIntensity(object : Light) : Float {
		return object.intensity;
	}

	public static function get3DLightDistance(object : PointLight) : Float {
		return object.distance;
	}

	public static function get3DLightDecay(object : PointLight) : Float {
		return object.decay;
	}



	public static function make3DBoxGeometry(width : Float, height : Float, depth : Float, widthSegments : Int, heightSegments : Int, depthSegments : Int) : Geometry {
		return new BoxGeometry(width, height, depth, widthSegments, heightSegments, depthSegments);
	}

	public static function make3DCircleGeometry(radius : Float, segments : Int, thetaStart : Float, thetaLength : Float) : Geometry {
		return new CircleGeometry(radius, segments, thetaStart, thetaLength);
	}

	public static function make3DConeGeometry(radius : Float, height : Float, radialSegments : Int, heightSegments : Int, openEnded : Bool, thetaStart : Float, thetaLength : Float) : Geometry {
		return new ConeGeometry(radius, height, radialSegments, heightSegments, openEnded, thetaStart, thetaLength);
	}

	public static function make3DCylinderGeometry(radiusTop : Float, radiusBottom : Float, height : Float, radialSegments : Int, heightSegments : Int, openEnded : Bool, thetaStart : Float, thetaLength : Float) : Geometry {
		return new CylinderGeometry(radiusTop, radiusBottom, height, radialSegments, heightSegments, openEnded, thetaStart, thetaLength);
	}

	public static function make3DMeshBasicMaterial(color : Int, parameters : Array<Array<String>>) : Material {
		return new MeshBasicMaterial({color : color});
	}


	public static function make3DMesh(geometry : Geometry, material : Material) : Mesh {
		return new Mesh(geometry, material);
	}


	public static function set3DAnimationDuration(animation : AnimationClip, duration : Float) : Void {
		animation.duration = duration;
	}

	public static function get3DAnimationDuration(animation : AnimationClip) : Float {
		return animation.duration;
	}

	public static function create3DAnimationMixer(object : Object3D) : AnimationMixer {
		var mixer : Dynamic = untyped __js__("new THREE.AnimationMixer(object)");
		mixer.clock = new Clock();
		return mixer;
	}

	public static function start3DAnimationMixer(mixer : AnimationMixer, animation : AnimationClip) : Void -> Void {
		var action = mixer.clipAction(animation);
		var drawFrameFn = function() {
			mixer.update(untyped mixer.clock.getDelta());
			RenderSupportJSPixi.InvalidateStage();
		};

		action.play();
		RenderSupportJSPixi.on('drawframe', drawFrameFn);

		return function() {
			action.stop();
			RenderSupportJSPixi.off('drawframe', drawFrameFn);
		}
	}
}