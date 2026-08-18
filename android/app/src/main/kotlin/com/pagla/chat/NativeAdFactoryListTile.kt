package com.pagla.chat

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactoryListTile(private val layoutInflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.my_native_ad, null) as NativeAdView

        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        adView.bodyView = adView.findViewById<TextView>(R.id.ad_body)
        adView.callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)

        (adView.headlineView as TextView).text = nativeAd.headline
        
        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}