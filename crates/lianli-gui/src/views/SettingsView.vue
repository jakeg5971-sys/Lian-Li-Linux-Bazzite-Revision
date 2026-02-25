<script setup lang="ts">
import { ref, computed, onMounted } from "vue";
import { invoke } from "@tauri-apps/api/core";
import { useDeviceStore } from "../stores/devices";
import { useConfigStore } from "../stores/config";
import PageHeader from "../components/PageHeader.vue";

const deviceStore = useDeviceStore();
const configStore = useConfigStore();
const socketPath = ref("...");

const openrgbStatus = computed(() => deviceStore.telemetry.openrgb_status);
const rgbConfig = computed(() => configStore.rgbConfig);

function updateOpenRgbPort(port: number) {
  const cfg = rgbConfig.value ?? {
    enabled: true,
    openrgb_server: false,
    openrgb_port: 6743,
    devices: [],
  };
  configStore.updateRgbConfig({ ...cfg, openrgb_port: port });
}

function toggleOpenRgbServer() {
  const cfg = rgbConfig.value ?? {
    enabled: true,
    openrgb_server: false,
    openrgb_port: 6743,
    devices: [],
  };
  configStore.updateRgbConfig({ ...cfg, openrgb_server: !cfg.openrgb_server });
}

onMounted(async () => {
  socketPath.value = await invoke<string>("get_socket_path");
});
</script>

<template>
  <div>
    <PageHeader title="Settings">
      <template #actions>
        <button
          @click="configStore.save()"
          :disabled="!configStore.dirty || configStore.loading"
          class="px-4 py-1.5 text-sm rounded-lg font-medium transition-colors"
          :class="
            configStore.dirty
              ? 'bg-blue-500 text-white hover:bg-blue-600 cursor-pointer'
              : 'bg-gray-200 dark:bg-gray-700 text-gray-400 cursor-not-allowed'
          "
        >
          {{ configStore.loading ? "Saving..." : "Save" }}
        </button>
      </template>
    </PageHeader>

    <div class="max-w-lg space-y-6">
      <!-- Daemon status -->
      <div class="rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-5">
        <h3 class="font-semibold text-sm mb-3">Daemon Status</h3>
        <div class="space-y-2 text-sm">
          <div class="flex items-center justify-between">
            <span class="text-gray-500 dark:text-gray-400">Connection</span>
            <span
              class="flex items-center gap-1.5"
              :class="deviceStore.daemonConnected ? 'text-green-600 dark:text-green-400' : 'text-red-500'"
            >
              <span
                class="w-2 h-2 rounded-full"
                :class="deviceStore.daemonConnected ? 'bg-green-500' : 'bg-red-500'"
              />
              {{ deviceStore.daemonConnected ? "Connected" : "Disconnected" }}
            </span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-gray-500 dark:text-gray-400">Socket</span>
            <span class="font-mono text-xs">{{ socketPath }}</span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-gray-500 dark:text-gray-400">Streaming</span>
            <span>{{ deviceStore.telemetry.streaming_active ? "Active" : "Idle" }}</span>
          </div>
        </div>
      </div>

      <!-- Config settings -->
      <div class="rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-5">
        <h3 class="font-semibold text-sm mb-3">Configuration</h3>
        <div class="space-y-3">
          <div>
            <label class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">
              Default FPS
            </label>
            <input
              type="number"
              :value="configStore.config?.default_fps ?? 30"
              @input="configStore.setDefaultFps(parseFloat(($event.target as HTMLInputElement).value) || 30)"
              class="w-40 px-2.5 py-1.5 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700"
              min="1"
              max="60"
              step="1"
            />
          </div>

          <div class="flex items-center justify-between text-sm">
            <span class="text-gray-500 dark:text-gray-400">LCD entries</span>
            <span>{{ configStore.lcds.length }}</span>
          </div>
          <div class="flex items-center justify-between text-sm">
            <span class="text-gray-500 dark:text-gray-400">Fan curves</span>
            <span>{{ configStore.fanCurves.length }}</span>
          </div>

        </div>
      </div>

      <!-- OpenRGB SDK Server -->
      <div class="rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-5">
        <h3 class="font-semibold text-sm mb-3">OpenRGB SDK Server</h3>
        <div class="space-y-3">
          <div class="flex items-center justify-between text-sm">
            <span class="text-gray-500 dark:text-gray-400">Server</span>
            <button
              @click="toggleOpenRgbServer"
              class="flex items-center gap-1.5 px-2.5 py-1 text-xs rounded-lg border transition-all cursor-pointer"
              :class="
                rgbConfig?.openrgb_server
                  ? 'bg-green-50 dark:bg-green-900/30 border-green-300 dark:border-green-700 text-green-700 dark:text-green-300 hover:bg-green-100 dark:hover:bg-green-900/50'
                  : 'bg-white dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600'
              "
            >
              <span
                class="inline-block w-2 h-2 rounded-full"
                :class="rgbConfig?.openrgb_server ? 'bg-green-500' : 'bg-gray-400'"
              />
              {{ rgbConfig?.openrgb_server ? "Enabled" : "Disabled" }}
            </button>
          </div>

          <div>
            <label class="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">
              Port
            </label>
            <input
              type="number"
              :value="rgbConfig?.openrgb_port ?? 6743"
              @input="updateOpenRgbPort(parseInt(($event.target as HTMLInputElement).value) || 6743)"
              class="w-40 px-2.5 py-1.5 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700"
              min="1024"
              max="65535"
            />
          </div>

          <div class="flex items-center justify-between text-sm">
            <span class="text-gray-500 dark:text-gray-400">Status</span>
            <span class="flex items-center gap-1.5 text-xs">
              <span
                class="w-2 h-2 rounded-full"
                :class="
                  openrgbStatus.running ? 'bg-green-500'
                  : openrgbStatus.error ? 'bg-red-500'
                  : !rgbConfig?.openrgb_server ? 'bg-gray-400'
                  : 'bg-yellow-500'
                "
              />
              <span :class="
                openrgbStatus.running ? 'text-green-600 dark:text-green-400'
                : openrgbStatus.error ? 'text-red-500'
                : !rgbConfig?.openrgb_server ? 'text-gray-500 dark:text-gray-400'
                : 'text-yellow-600 dark:text-yellow-400'
              ">
                {{
                  openrgbStatus.running ? `Listening on port ${openrgbStatus.port}`
                  : openrgbStatus.error ? openrgbStatus.error
                  : !rgbConfig?.openrgb_server ? 'Disabled'
                  : 'Starting...'
                }}
              </span>
            </span>
          </div>
        </div>
      </div>

      <!-- About -->
      <div class="rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-5">
        <h3 class="font-semibold text-sm mb-3">About</h3>
        <div class="space-y-1 text-sm text-gray-500 dark:text-gray-400">
          <div>Lian Li Linux v0.1.0</div>
          <div>Linux replacement for L-Connect 3</div>
          <div class="text-xs mt-2">Fan speed control + LCD streaming for all Lian Li devices</div>
        </div>
      </div>
    </div>
  </div>
</template>
