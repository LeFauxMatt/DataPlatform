# Homelab map

The infrastructure this pipeline runs on: network gear, hosts and the services each runs.
Generated from the homelab's own config (a few services are left out of this public copy).

```mermaid
flowchart TB
  internet(("Internet"))
  subgraph home["🏠 Home LAN"]
    direction TB
    udm["UniFi UDM Pro<br/><small>router · firewall</small>"]:::gear
    usw["UniFi USW Pro Max 16<br/><small>switch</small>"]:::gear
    eero["eero mesh<br/><small>Wi-Fi: Lucas WiFi</small>"]:::gear
    mac_mini["<b>mac-mini</b><br/><small>local AI</small>"]:::host
    android_phone["<b>android phone</b><br/><small>app automation</small>"]:::host
    subgraph nucbox["<b>nucbox</b><br/><small>private tailnet services</small>"]
      direction TB
      stack_homepage["homepage"]:::tailnet
      stack_mcp["mcp"]:::tailnet
      stack_nucbox_dns["nucbox-dns"]:::tailnet
      stack_nucbox_proxy["nucbox-proxy"]:::tailnet
      stack_speedtest["speedtest"]:::tailnet
      stack_homepage ~~~ stack_speedtest
    end
    subgraph unraid["<b>unraid</b><br/><small>NAS</small>"]
      direction TB
      stack_audiobookshelf["audiobookshelf"]:::tailnet
      stack_backrest["backrest"]:::tailnet
      stack_bookorbit["bookorbit"]:::tailnet
      stack_esphome["esphome"]:::tailnet
      stack_fileflows["fileflows"]:::tailnet
      stack_forgejo["forgejo"]:::tailnet
      stack_immich["immich"]:::tailnet
      stack_jellyfin["jellyfin"]:::tailnet
      stack_karakeep["karakeep"]:::tailnet
      stack_manyfold["manyfold"]:::tailnet
      stack_metube["metube"]:::tailnet
      stack_miniflux["miniflux"]:::tailnet
      stack_monica["monica"]:::tailnet
      stack_paperless["paperless"]:::tailnet
      stack_restic_server["restic-server"]:::tailnet
      stack_romm["romm"]:::tailnet
      stack_seafile["seafile"]:::tailnet
      stack_unraid_proxy["unraid-proxy"]:::tailnet
      stack_youtube_dl["youtube-dl"]:::tailnet
      stack_audiobookshelf ~~~ stack_fileflows
      stack_backrest ~~~ stack_forgejo
      stack_bookorbit ~~~ stack_immich
      stack_esphome ~~~ stack_jellyfin
      stack_fileflows ~~~ stack_karakeep
      stack_forgejo ~~~ stack_manyfold
      stack_immich ~~~ stack_metube
      stack_jellyfin ~~~ stack_miniflux
      stack_karakeep ~~~ stack_monica
      stack_manyfold ~~~ stack_paperless
      stack_metube ~~~ stack_restic_server
      stack_miniflux ~~~ stack_romm
      stack_monica ~~~ stack_seafile
      stack_paperless ~~~ stack_unraid_proxy
      stack_restic_server ~~~ stack_youtube_dl
    end
    homeassistant["<b>homeassistant</b><br/><small>home automation</small>"]:::host
    pi3b["<b>pi3b</b><br/><small>lightweight workloads</small>"]:::host
    subgraph pi4["<b>pi4</b><br/><small>lightweight workloads</small>"]
      direction TB
      stack_homebox["homebox"]:::tailnet
      stack_linkding["linkding"]:::tailnet
      stack_mealie["mealie"]:::tailnet
      stack_papra["papra"]:::tailnet
      stack_pocket_id["pocket-id"]:::tailnet
      stack_theme_park["theme-park"]:::tailnet
      stack_twitch_miner["twitch-miner"]:::tailnet
      stack_homebox ~~~ stack_pocket_id
      stack_linkding ~~~ stack_theme_park
      stack_mealie ~~~ stack_twitch_miner
    end
  end
  subgraph offsite_ovh_cloud["☁️ Off-site"]
    subgraph ovh_cloud["<b>ovh-cloud</b><br/><small>internet-facing services</small>"]
      direction TB
      stack_infisical["infisical"]:::tailnet
      stack_kutt["kutt"]:::public
      stack_littlelink["littlelink"]:::public
      stack_minecraft["minecraft"]:::public
      stack_ovh_dns["ovh-dns"]:::tailnet
      stack_ovh_proxy["ovh-proxy"]:::tailnet
      stack_picoshare["picoshare"]:::public
      stack_uptime_kuma["uptime-kuma"]:::tailnet
      stack_infisical ~~~ stack_ovh_dns
      stack_kutt ~~~ stack_ovh_proxy
      stack_littlelink ~~~ stack_picoshare
      stack_minecraft ~~~ stack_uptime_kuma
    end
  end
  subgraph swarm_any["🐝 homelab swarm: any node, or several"]
    stack_changedetection["changedetection<br/><small>on nucbox, pi4</small>"]:::tailnet
    stack_swarm_socket_proxy["swarm-socket-proxy<br/><small>on every node</small>"]:::tailnet
    stack_volume_backup["volume-backup<br/><small>on every node</small>"]:::tailnet
  end
  tailnet{{"Tailscale tailnet"}}:::ts
  internet --- udm
  udm ---|"~1 Gb/s uplink"| usw
  usw --- eero
  usw --- mac_mini
  mac_mini -.- tailnet
  mac_mini ---|USB| android_phone
  usw --- nucbox
  nucbox -.- tailnet
  usw --- unraid
  unraid -.- tailnet
  internet --- ovh_cloud
  ovh_cloud -.- tailnet
  usw --- homeassistant
  homeassistant -.- tailnet
  usw --- pi3b
  pi3b -.- tailnet
  usw --- pi4
  pi4 -.- tailnet
  classDef gear fill:#e8f0fe,stroke:#1a73e8,color:#0b3d91
  classDef public fill:#fde7d9,stroke:#d9480f,color:#7a2600
  classDef tailnet fill:#eef6ee,stroke:#2f9e44,color:#1b4d26
  classDef empty fill:none,stroke:#adb5bd,stroke-dasharray:3 3,color:#868e96
  classDef swarm stroke-dasharray:5 3
  classDef host fill:#f8f9fa,stroke:#495057,color:#212529
  classDef ts fill:#f3e8ff,stroke:#7048e8,color:#3b1f8f
  class stack_homepage,stack_speedtest,stack_homebox,stack_linkding,stack_mealie,stack_papra,stack_pocket_id,stack_theme_park,stack_twitch_miner,stack_changedetection,stack_swarm_socket_proxy,stack_volume_backup swarm
  legend["<b>Key</b><br/>orange: public on the internet · green: tailnet only<br/>dashed border: swarm service · dotted line: Tailscale peer"]:::empty
```
