<?php

namespace App\Services\AiAgent;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Services\AiAgent\Tools\CxcTools;

class OpenAiService
{
    protected $apiKey;
    protected $model = 'gpt-5.6-luna';
    protected $baseUrl = 'https://api.openai.com/v1/chat/completions';

    public function __construct()
    {
        $this->apiKey = env('OPENAI_API_KEY');
    }

    /**
     * Envía un mensaje a OpenAI, maneja las herramientas y devuelve la respuesta final.
     */
    public function chat($userMessage, $history = [])
    {
        if (empty($this->apiKey)) {
            return "Error: OPENAI_API_KEY no está configurada en el archivo .env";
        }

        // 1. Preparar las herramientas disponibles
        $tools = CxcTools::getToolDefinitions();

        // 2. Preparar el historial de mensajes
        $messages = [];
        
        $messages[] = [
            'role' => 'system',
            'content' => 'Eres un asistente inteligente para un sistema de facturación y restaurante. 
                          Tu trabajo es ayudar al usuario a obtener información. 
                          Usa las herramientas proporcionadas cuando sea necesario. 
                          Responde de forma concisa y amigable.'
        ];
        
        // Agregar el mensaje actual del usuario
        $messages[] = [
            'role' => 'user',
            'content' => $userMessage
        ];

        $payload = [
            'model' => $this->model,
            'messages' => $messages,
            'tools' => $tools,
            'tool_choice' => 'auto'
        ];

        // 3. Primera llamada a OpenAI
        $response = Http::withoutVerifying()->withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Content-Type' => 'application/json',
        ])->post($this->baseUrl, $payload);
        
        if ($response->failed()) {
            Log::error('Error en OpenAI API', ['response' => $response->json()]);
            return "Ocurrió un error al consultar la IA (OpenAI).";
        }

        $responseData = $response->json();
        $responseMessage = $responseData['choices'][0]['message'];
        
        // 4. Revisar si OpenAI quiere llamar a una función
        if (isset($responseMessage['tool_calls'])) {
            $toolCall = $responseMessage['tool_calls'][0];
            $functionName = $toolCall['function']['name'];
            $functionArgs = json_decode($toolCall['function']['arguments'], true);
            
            Log::info("OpenAI solicitó ejecutar la función: {$functionName}", ['args' => $functionArgs]);

            // Ejecutar la función localmente
            $functionResult = [];
            if ($functionName === 'consultar_deuda_cliente') {
                $functionResult = CxcTools::consultarDeudaCliente($functionArgs['nombre_cliente'] ?? '');
            } else {
                $functionResult = ['status' => 'error', 'message' => 'Herramienta no encontrada'];
            }

            // 5. Devolver el resultado de la función a OpenAI
            $messages[] = $responseMessage; // Añadimos la respuesta del asistente con el tool_call
            $messages[] = [
                'role' => 'tool',
                'tool_call_id' => $toolCall['id'],
                'name' => $functionName,
                'content' => json_encode($functionResult)
            ];
            
            $secondPayload = [
                'model' => $this->model,
                'messages' => $messages,
                'tools' => $tools
            ];

            $secondResponse = Http::withoutVerifying()->withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Content-Type' => 'application/json',
            ])->post($this->baseUrl, $secondPayload);
            
            if ($secondResponse->successful()) {
                $secondResponseData = $secondResponse->json();
                if (isset($secondResponseData['choices'][0]['message']['content'])) {
                    return $secondResponseData['choices'][0]['message']['content'];
                }
            }
            
            return "Ejecuté la herramienta pero hubo un problema generando la respuesta final.";
        }

        // Si no llamó a ninguna función, devolvemos el texto directamente
        if (isset($responseMessage['content'])) {
            return $responseMessage['content'];
        }

        return "No pude entender la solicitud.";
    }
}
