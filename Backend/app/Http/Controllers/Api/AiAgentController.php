<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\AiAgent\OpenAiService;

class AiAgentController extends Controller
{
    protected $aiService;

    public function __construct(OpenAiService $aiService)
    {
        $this->aiService = $aiService;
    }

    public function chat(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
            // 'history' => 'nullable|array' // Opcional para mantener el contexto
        ]);

        $userMessage = $request->input('message');
        $history = $request->input('history', []);

        $response = $this->aiService->chat($userMessage, $history);

        return response()->json([
            'status' => 'success',
            'response' => $response
        ]);
    }
}
