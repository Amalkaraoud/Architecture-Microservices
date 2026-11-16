package com.exemple.rest;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/calcul")
public class CalculRest {

    private final Calculatrice calculService = new Calculatrice();

    // GET /calcul/somme?a=2&b=3
    @GET
    @Path("/somme")
    @Produces(MediaType.TEXT_PLAIN)
    public Response somme(@QueryParam("a") int a, @QueryParam("b") int b) {
        int result = calculService.somme(a, b);
        return Response.ok(result).build();
    }

    // GET /calcul/soustraction?a=10&b=4
    @GET
    @Path("/soustraction")
    @Produces(MediaType.TEXT_PLAIN)
    public Response soustraction(@QueryParam("a") int a, @QueryParam("b") int b) {
        int result = calculService.soustraction(a, b);
        return Response.ok(result).build();
    }

    // GET /calcul/produit?a=6&b=7
    @GET
    @Path("/produit")
    @Produces(MediaType.TEXT_PLAIN)
    public Response produit(@QueryParam("a") int a, @QueryParam("b") int b) {
        int result = calculService.produit(a, b);
        return Response.ok(result).build();
    }

    // GET /calcul/division?a=7&b=2 (400 si b = 0)
    @GET
    @Path("/division")
    @Produces(MediaType.TEXT_PLAIN)
    public Response division(@QueryParam("a") int a, @QueryParam("b") int b) {
        if (b == 0) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Erreur : division par 0 impossible")
                    .build();
        }
        double result = calculService.division(a, b);
        return Response.ok(result).build();
    }

    // GET /calcul/produit/6/7 (paramètres dans le chemin)
    @GET
    @Path("/produit/{a}/{b}")
    @Produces(MediaType.TEXT_PLAIN)
    public Response produitChemin(@PathParam("a") int a, @PathParam("b") int b) {
        int result = calculService.produit(a, b);
        return Response.ok(result).build();
    }

    // GET /calcul/somme/detail?a=2&b=3 : réponse JSON
    @GET
    @Path("/somme/detail")
    @Produces(MediaType.APPLICATION_JSON)
    public Response sommeDetail(@QueryParam("a") int a, @QueryParam("b") int b) {
        Resultat resultat = new Resultat("somme", a, b, calculService.somme(a, b));
        return Response.ok(resultat).build();
    }

    // GET /calcul/division/detail?a=7&b=2 : réponse JSON (400 si b = 0) - exercice E.4
    @GET
    @Path("/division/detail")
    @Produces(MediaType.APPLICATION_JSON)
    public Response divisionDetail(@QueryParam("a") int a, @QueryParam("b") int b) {
        if (b == 0) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erreur\":\"Division par 0 impossible\"}")
                    .build();
        }
        Resultat resultat = new Resultat("division", a, b, calculService.division(a, b));
        return Response.ok(resultat).build();
    }
}