'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"index.html": "36581c116cd234d559f55b17a4ef2441",
"/": "36581c116cd234d559f55b17a4ef2441",
"flutter_bootstrap.js": "3a3257a5cd0d9c1cd264dc9e624c5e17",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "4eec09bc142a15273ca93a24be6239f8",
"assets/FontManifest.json": "2e98115db01df130ffa9b1c715600343",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "c0ad29d56cfe3890223c02da3c6e0448",
"assets/NOTICES": "bee2cf4049d759018181ac5869820a36",
"assets/assets/fonts/PlusJakartaSans-SemiBold.ttf": "74b5e3605ec728c164998f8e82e21063",
"assets/assets/fonts/PlusJakartaSans-Bold.ttf": "e05d8101e6de185813387dbb6295c900",
"assets/assets/fonts/PlusJakartaSans-ExtraBold.ttf": "8ac4bf0bb59d36398d0e61ce57321567",
"assets/assets/fonts/PlusJakartaSans-Regular.ttf": "c7960ae86272d0aca99da5432b6d635e",
"assets/assets/fonts/PlusJakartaSans-Medium.ttf": "6449d720976dafc2874b17d298faabaa",
"assets/assets/logo_icon.png": "cfc8790f02fa854e07238b937d9ee4f0",
"assets/assets/logo_horizontal.png": "2e1cd3d37569565314b9baf674eb3d5f",
"assets/AssetManifest.bin": "1033cc6057599e661df0401e34ea8797",
"assets/AssetManifest.bin.json": "3e15475dc1184cb84e7b49cda75d0d64",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf": "73d986a02d9e5562559262e1d6daf7a3",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf": "43f25766dafaefdbca4cdd7031106ae3",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf": "d256c8178348d2afbc8a4a1ac1d7b710",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf": "4de5aad377674cde06b64959f521a0bb",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf": "789087ab696129693097122e7de0acf5",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf": "4c40d9c3eee6cbb3857af740dda49f8f",
"assets/packages/lucide_icons_flutter/assets/lucide.ttf": "04a1e6ecc2a7a07d076bb89134073732",
"assets/packages/esc_pos_utils_plus/resources/capabilities.json": "cfcc98d389d1ee4358f773efe8a9cdac",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/win_ble/assets/BLEServer.exe": "28aa0e2566083c860f029ff4bc32c4ce",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"icons/Icon-512.png": "c6fb9c4e700d1bc657d656eb43c5dd32",
"icons/Icon-maskable-512.png": "c6fb9c4e700d1bc657d656eb43c5dd32",
"icons/Icon-192.png": "66fca5673332213c23677ad466c68a0a",
"icons/Icon-maskable-192.png": "66fca5673332213c23677ad466c68a0a",
"manifest.json": "e3168cd8366e078dd46c291892f8747f",
"version.json": "28aa82b8283657f0b03eac09ca960a3e",
"main.dart.js": "758979af3688c9ed2581a14eabf6c1b0"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
