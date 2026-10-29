package com.example.ndokete

import android.view.WindowManager.LayoutParams
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Empêche les captures d'écran et masque l'aperçu dans le gestionnaire de tâches récent
        window.setFlags(LayoutParams.FLAG_SECURE, LayoutParams.FLAG_SECURE)
    }
}
