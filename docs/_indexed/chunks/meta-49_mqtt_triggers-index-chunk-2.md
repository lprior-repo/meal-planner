---
doc_id: meta/49_mqtt_triggers/index
chunk_id: meta/49_mqtt_triggers/index#chunk-2
heading_path: ["MQTT triggers", "How to use"]
chunk_type: prose
tokens: 393
summary: "How to use"
---

## How to use

### Configure MQTT resource
- Select an existing [MQTT resource](https://hub.windmill.dev/resource_types/225/mqtt) or create a new one
- Provide broker hostname and port
- Add authentication credentials and certificates as required by your broker

### Select runnable
- Choose the script or flow to execute when messages are published to your subscribed topics

### Configure topic subscriptions
- Specify one or more topics to subscribe to
- Set appropriate QoS level for each topic

#### Quality of Service (QoS) levels

| Level | Description | When to use |
|-------|-------------|-------------|
| **0** | **At most once** – Message delivered once or not at all without confirmation | Choose when it is okay for your script/flow to not be triggered (if the message is lost) or triggered only once. |
| **1** | **At least once** – Guaranteed delivery but may arrive multiple times | Choose when it is okay for your script/flow to be triggered again by an already received message from the broker. |
| **2** | **Exactly once** – Guaranteed delivery exactly once | Choose when you need your script/flow to be triggered only once and avoid any duplicates. |

For more information about MQTT QoS, see the [MQTT QoS Documentation](https://www.hivemq.com/blog/mqtt-essentials-part-6-mqtt-quality-of-service-levels/).

#### MQTT topic structure

MQTT topics are case-sensitive and follow a hierarchical structure (e.g., `home/sensor/temperature`).  
For best practices on MQTT topics, see the [MQTT Topics Documentation](https://www.hivemq.com/blog/mqtt-essentials-part-5-mqtt-topics-best-practices/).

### Advanced MQTT options

By default, Windmill uses **MQTT version 5**. However, you can choose to use **MQTT version 3** or **MQTT version 5** with specific associated options. 

- **MQTT v3 options**:
  - **Clean Session** (default: true): [Learn more](https://www.emqx.com/en/blog/mqtt5-new-feature-clean-start-and-session-expiry-interval#clean-session-in-mqtt-3-1-1)
  - **Client ID**: [Learn more](https://public.dhe.ibm.com/software/dw/webservices/ws-mqtt/mqtt-v3r1.html)
  
- **MQTT v5 options**:
  - **Clean Start** (default: true): [Learn more](https://www.emqx.com/en/blog/mqtt5-new-feature-clean-start-and-session-expiry-interval#introduction-to-clean-start)
  - **Session Expiry Interval**: [Learn more](https://www.emqx.com/en/blog/mqtt5-new-feature-clean-start-and-session-expiry-interval#introduction-to-session-expiry-interval)
  - **Topic Alias Maximum**: [Learn more](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901051)
  - **Client ID**: [Learn more](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901059)
