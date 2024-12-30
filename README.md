
# MakerAI Suite: Advanced AI Components for Delphi


## 📌 Project Description

The **MakerAI Suite** is a comprehensive set of Delphi components designed to seamlessly integrate artificial intelligence into your applications. With support for state-of-the-art models and functionalities, the suite includes tools for natural language processing, audio transcription, image generation, task orchestration, and retrieval-augmented generation (RAG).

### Core Components

- **Chat**: Integration with models like Anthropic, Gemini, Grok, Groq, Mistral, Ollama, and OpenAI.
- **Embeddings**: Vector-based text representations using Grok, Groq, Mistral, Ollama, and OpenAI.
- **Audio**: Powered by Whisper (OpenAI), for transcription and translation.
- **RAG**: Retrieval-augmented generation using all supported models.
- **Graph**: Task orchestration via TAiGraph, enabling visual workflow creation.

---

## 🌟 Key Features

### TAiChat
- **Broad Compatibility**: Supports multiple AI models like GPT-4, Claude, Mistral, and more.
- **File Attachments**: Processes images, audios, and other media inputs.
- **Async Mode**: Real-time feedback for improved user experiences.
- **Tool Integration**: Enables interaction with external tools for queries and tasks.

### TAiAudio
- **Transcription**: Converts audio into text.
- **Translation**: Translates audio content between languages.
- **Voice Synthesis**: Generates spoken audio from text.

### TAiDalle
- **Image Generation**: Creates images from text descriptions.
- **Image Editing**: Modifies existing images using masks.
- **Variations**: Produces alternate versions of an image.

### TAiGraph
- **Visual Task Orchestration**: Simplifies workflow design using graph-based structures.
- **Modular Design**: Facilitates the integration of AI components and external tools.
- **Contextual Workflows**: Builds dynamic systems that adapt to changing contexts.

### RAG Integration
- **Contextual Queries**: Combines language models with context retrieved from vector databases.
- **Database Support**: Works with PostgreSQL (pg_vector) and in-memory embeddings.
- **Scalability**: Handles large datasets for advanced AI-powered systems.

---

## 🎯 Use Cases

### 🌐 **TAiChat**
1. **Virtual Assistants**: Manages complex queries and provides contextual support.
2. **Sentiment Analysis**: Detects tones in social media or survey data.
3. **Content Generation**: Summarizes, generates reports, or writes articles.

### 🎧 **TAiAudio**
1. **Automatic Subtitling**: Creates subtitles for videos.
2. **Voice Assistants**: Enables voice commands for chatbots and applications.
3. **Meeting Documentation**: Transcribes conferences or interviews.

### 🎨 **TAiDalle**
1. **Visual Design**: Creates illustrations from descriptions.
2. **Prototyping**: Generates quick visual concepts.
3. **Creative Editing**: Enhances images using AI.

### 🧩 **TAiGraph**
1. **Task Automation**: Builds workflows for business processes.
2. **AI-Enhanced Operations**: Integrates AI models into dynamic, adaptive pipelines.
3. **Visual System Design**: Creates modular systems with intuitive graph interfaces.

### 🔍 **RAG**
1. **Semantic Search**: Retrieves precise information from large datasets.
2. **Knowledge-Based Systems**: Enhances AI responses with specific contextual knowledge.
3. **Custom AI Assistants**: Builds powerful tools for industries like healthcare or finance.

---

## 📚 Examples

### 🛠️ TAiChat
```delphi
var
  Chat: TAiChat;
begin
  Chat := TAiChat.Create(nil);
  try
    Chat.ApiKey := 'your-api-key';
    Chat.Model := 'gpt-4';
    Chat.AddMessage('What is the capital of France?', 'user');
    ShowMessage(Chat.Run);
  finally
    Chat.Free;
  end;
end;
```

### 🧩 TAiGraph
```delphi
var
  Graph: TAiGraph;
begin
  Graph := TAiGraph.Create(nil);
  try
    Graph.AddNode('Start', 'Initial Task');
    Graph.AddNode('AI Analysis', 'Analyze Data', [aiProcessing]);
    Graph.ConnectNodes('Start', 'AI Analysis');
    Graph.Execute;
  finally
    Graph.Free;
  end;
end;
```

### 🔍 RAG
```delphi
var
  RagChat: TAiRagChat;
begin
  RagChat := TAiRagChat.Create(nil);
  try
    RagChat.DataVec := TAiDataVec.Create;
    RagChat.ChatModel := TAiOpenChat.Create('config.json');
    ShowMessage(RagChat.QueryWithContext('What is the system about?'));
  finally
    RagChat.Free;
  end;
end;
```

---

## 🛠️ Setup

### Requirements
1. Delphi 11 or higher.
2. API keys for supported models (e.g., OpenAI, Anthropic).
3. Dependencies:
   - `System.Net.HttpClient`
   - `System.JSON`
   - `REST.Client`

### Installation
1. Clone this repository.
2. Configure API keys in the component properties (e.g., `ApiKey`).
3. Follow the examples to integrate components into your Delphi project.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Gustavo Enríquez**  
- LinkedIn: [Profile](https://www.linkedin.com/in/gustavo-enriquez-3937654a/)  
- YouTube: [Channel](https://www.youtube.com/@cimamaker3945)  
- GitHub: [Repository](https://github.com/gustavoeenriquez/)  

Want to contribute? Feel free to fork and suggest improvements!

