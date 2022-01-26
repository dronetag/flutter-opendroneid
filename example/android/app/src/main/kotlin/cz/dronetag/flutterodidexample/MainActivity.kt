package cz.dronetag.flutterodidexample

import android.Manifest
import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager

import androidx.core.app.ActivityCompat
import io.flutter.Log

class MainActivity: FlutterActivity() {
    private val RC_LOCATION = 1

    override fun onResume() {
        super.onResume()
        val location = Manifest.permission.ACCESS_COARSE_LOCATION
        val location_fine = Manifest.permission.ACCESS_FINE_LOCATION
        val wifi_state = Manifest.permission.ACCESS_WIFI_STATE
        val network_state = Manifest.permission.ACCESS_NETWORK_STATE
        val internet = Manifest.permission.INTERNET
        if (ActivityCompat.checkSelfPermission(
                this,
                location
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf<String>("android.permission.ACCESS_COARSE_LOCATION"), RC_LOCATION)
        } else {
            Log.d("activity", "onResume: rc loc permission granted")
        }

        if (ActivityCompat.checkSelfPermission(
                this,
                location_fine
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            //ActivityCompat.requestPermissions(this, arrayOf<String>("android.permission.ACCESS_COARSE_LOCATION"), RC_LOCATION)
        } else {
            Log.d("activity", "onResume: precise permission granted")
        }

        if (ActivityCompat.checkSelfPermission(
                this,
                wifi_state
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            //ActivityCompat.requestPermissions(this, arrayOf<String>("android.permission.ACCESS_COARSE_LOCATION"), RC_LOCATION)
        } else {
            Log.d("activity", "onResume: wifi permission granted")
        }

        if (ActivityCompat.checkSelfPermission(
                this,
                internet
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            //ActivityCompat.requestPermissions(this, arrayOf<String>("android.permission.ACCESS_COARSE_LOCATION"), RC_LOCATION)
        } else {
            Log.d("activity", "onResume: internet permission granted")
        }

        if (ActivityCompat.checkSelfPermission(
                this,
                network_state
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            //ActivityCompat.requestPermissions(this, arrayOf<String>("android.permission.ACCESS_COARSE_LOCATION"), RC_LOCATION)
        } else {
            Log.d("activity", "onResume: network state permission granted")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RC_LOCATION) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d("activity", "rc loc permisson granted")
            } else {
                Log.d("activity", "rc loc permisson rejected")
            }
        } else {
            super.onRequestPermissionsResult(requestCode, permissions!!, grantResults)
        }
    }

}
